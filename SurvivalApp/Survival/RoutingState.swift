//
//  RoutingState.swift
//  Survival
//
//  Created by 张国晔 on 2016/11/1.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import MapKit

class RoutingState: State {
    weak var delegate: StateDelegate?
    
    private var routes = [Route]()
    private var routeForPolyline = [MKPolyline: Route]()
    
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
    
    init(from: Location, to: Location) {
        let route = Route(from: from, to: to)
        routes.append(route)
        route.calculateRoute {
            var coordinates = $0
            let polyline = MKPolyline(coordinates: &coordinates, count: coordinates.count)
            self.routeForPolyline[polyline] = route
            self.delegate?.didGenerateOverlays([polyline])
            if let fromPoint = coordinates.first, let toPoint = coordinates.last {
                RoutingState.avoidLinkIds(from: fromPoint, to: toPoint) {
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
    }
}
