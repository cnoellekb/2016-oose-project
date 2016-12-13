//
//  RoutingState.swift
//  Survival 
//  
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

class RoutingState: State {
    weak var delegate: StateDelegate?
    
    ///Array of routes
    private var routes = [Route]()
    /// HashMap from Polyline to Route (stroke color to route)
    private var routeForPolyline = [MKPolyline: Route]()
  
    /// Remove current annotations
    /**
    Annotation = superclass of overlay, overlay is annotation
    
    When 'overlay is stated' we refer to annotation
    */  
    var annotations: [MKAnnotation] {
        return []
    }
    var overlays: [MKOverlay] {
        return Array(routeForPolyline.keys)
    }
    
    func strokeColor(for annotation: MKAnnotation) -> UIColor? {
        if let polyline = annotation as? MKPolyline,
                let route = routeForPolyline[polyline] {
            return route.color
        }
        return nil
    }

    /* This retrieves the avoidLink IDs, upon completion 
    
    Will retrieve & download result and call completion closure 
        
    */    
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

    /**
    Inititializes routing state and starts to query for the routes -- 3 types of routes (safest,
    middle, fastest)
    */
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        let route = Route(from: from, to: to)
        routes.append(route)
        route.calculateRoute {
            var coordinates = $0
            let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
            self.routeForPolyline[polyline] = route
            self.delegate?.didGenerateOverlays([polyline])
        }
        RoutingState.avoidLinkIds(from: from, to: to) {
            let middleRoute = MiddleRoute(from: from, to: to, avoidLinkIds: $0)
            self.routes.append(middleRoute)
            middleRoute.calculateRoute {
                var coordinates = $0
                let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.routeForPolyline[polyline] = middleRoute
                self.delegate?.didGenerateOverlays([polyline])
            }
            let safestRoute = SafestRoute(from: from, to: to, avoidLinkIds: $0)
            self.routes.append(safestRoute)
            safestRoute.calculateRoute {
                var coordinates = $0
                let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
                self.routeForPolyline[polyline] = safestRoute
                self.delegate?.didGenerateOverlays([polyline])
            }
        }
    }
}
