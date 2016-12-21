//
//  RoutingState.swift
//  Survival 
//  
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

/// State of routing
class RoutingState: State, RoutingViewControllerDelegate {
    /// Event delegate
    weak var delegate: StateDelegate?
    
    /// Array of routes (order: safest, middle, fastest)
    var routes = [Route?](repeating: nil, count: 3)
    /// Dictionary from MKPolyline to Route
    private var routeForPolyline = [MKPolyline: Route]()
    
    /// All overlays generated here
    var overlays: [MKOverlay] {
        return Array(routeForPolyline.keys)
    }
    
    /// Stroke color for overlay
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor? {
        if let polyline = overlay as? MKPolyline,
                let route = routeForPolyline[polyline] {
            return route.color
        }
        return nil
    }
    
    /// Retrieve linkIds to avoid
    ///
    /// - Parameters:
    ///   - from: origination
    ///   - to: destination
    ///   - completion: called when request is completed
    static func avoidLinkIds(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: @escaping (AvoidLinkIds) -> ()) {
        var urlComponents = server
        urlComponents.path = "/v1/avoidLinkIds"
        urlComponents.queryItems = [
            URLQueryItem(name: "fromLat", value: "\(from.latitude)"),
            URLQueryItem(name: "toLat", value: "\(to.latitude)"),
            URLQueryItem(name: "fromLng", value: "\(from.longitude)"),
            URLQueryItem(name: "toLng", value: "\(to.longitude)")
        ]
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: [Int]],
                    let red = json["red"], let yellow = json["yellow"] else {
                return
            }
            completion(AvoidLinkIds(red: red, yellow: yellow))
        }.resume()
    }
    
    /// Initializes routing state and starts to query for routes
    ///
    /// - Parameters:
    ///   - from: origination
    ///   - to: destination
    init?(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        if MKMetersBetweenMapPoints(MKMapPointForCoordinate(from), MKMapPointForCoordinate(to)) > 100000 {
            return nil
        }
        let route = Route(from: from, to: to)
        route.calculateRoute {
            self.routes[2] = route
            self.handle(coordinates: route.shape, route: route)
        }
        RoutingState.avoidLinkIds(from: from, to: to) {
            let middleRoute = MiddleRoute(from: from, to: to, avoidLinkIds: $0)
            middleRoute.calculateRoute {
                self.routes[1] = middleRoute
                self.handle(coordinates: middleRoute.shape, route: middleRoute)
            }
            let safestRoute = SafestRoute(from: from, to: to, avoidLinkIds: $0)
            safestRoute.calculateRoute {
                self.routes[0] = safestRoute
                self.handle(coordinates: safestRoute.shape, route: safestRoute)
            }
        }
    }
    
    /// Handle routing result
    ///
    /// - Parameters:
    ///   - coordinates: coordinates of a route
    ///   - route: route
    private func handle(coordinates: [CLLocationCoordinate2D], route: Route) {
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        self.routeForPolyline[polyline] = route
        self.delegate?.didGenerate(overlay: polyline)
        self.routingViewController?.update()
    }
    
    /// Bottom view controller
    private weak var routingViewController: RoutingViewController?
    /// Bottom view controller for State protocol
    var bottomViewController: UIViewController? {
        return routingViewController
    }
    
    /// Bottom view controller segue name
    var bottomSegue: String? {
        return "Route"
    }
    
    /// Handle bottom view controller segue
    ///
    /// - Parameters:
    ///   - segue: Storyboard segue
    ///   - bottomHeight: bottom container height constraint
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint) {
        if let dst = segue.destination as? RoutingViewController {
            bottomHeight.constant = dst.preferredContentSize.height
            routingViewController = dst
            dst.delegate = self
        }
    }
    
    /// User choosed a route
    ///
    /// - Parameter route: chosen route
    func choose(route: Route) {
        delegate?.choose(route: route)
    }
    
    /// Report error of bottom view controller
    ///
    /// - Parameters:
    ///   - title: error title
    ///   - message: error message
    func reportError(title: String, message: String?) {
        delegate?.reportError(title: title, message: message)
    }
}
