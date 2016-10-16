//
//  Route.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/13.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import CoreLocation

class Route {
    var from, to: Location
    
    init(from: Location, to: Location) {
        self.from = from
        self.to = to
    }
    
    func calculateRoute(mustAvoid: [Int] = [], tryAvoid: [Int] = [], completion: @escaping ([CLLocationCoordinate2D]) -> ()) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "www.mapquestapi.com"
        urlComponents.path = "/directions/v2/route"
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: Bundle.main.object(forInfoDictionaryKey: "MQApplicationKey") as? String),
            URLQueryItem(name: "from", value: "\(from)"),
            URLQueryItem(name: "to", value: "\(to)"),
            URLQueryItem(name: "routeType", value: "pedestrian")
        ]
        if !mustAvoid.isEmpty {
            let linkIds = mustAvoid.map(String.init).joined(separator: ",")
            let queryItem = URLQueryItem(name: "mustAvoidLinkIds", value: linkIds)
            urlComponents.queryItems?.append(queryItem)
        }
        if !tryAvoid.isEmpty {
            let linkIds = tryAvoid.map(String.init).joined(separator: ",")
            let queryItem = URLQueryItem(name: "tryAvoidLinkIds", value: linkIds)
            urlComponents.queryItems?.append(queryItem)
        }
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let route = json["route"] as? [String: Any],
                    let sessionID = route["sessionId"] as? String else {
                print(error)
                return
            }
            Route.routeShape(ofSessionID: sessionID, completion: completion)
        }.resume()
        
    }
    
    private static func routeShape(ofSessionID id: String, completion: @escaping ([CLLocationCoordinate2D]) -> ()) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "www.mapquestapi.com"
        urlComponents.path = "/directions/v2/routeshape"
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: Bundle.main.object(forInfoDictionaryKey: "MQApplicationKey") as? String),
            URLQueryItem(name: "sessionId", value: id),
            URLQueryItem(name: "fullShape", value: "\(true)")
        ]
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let route = json["route"] as? [String: Any],
                    let shape = route["shape"] as? [String: Any],
                    let shapePoints = shape["shapePoints"] as? [Double] else {
                print(error)
                return
            }
            var coordinates = [CLLocationCoordinate2D]()
            coordinates.reserveCapacity(shapePoints.count / 2)
            var i = shapePoints.makeIterator()
            while let lat = i.next(), let lng = i.next() {
                coordinates.append(CLLocationCoordinate2D(latitude: lat, longitude: lng))
            }
            DispatchQueue.main.async {
                completion(coordinates)
            }
        }.resume()
    }
    
    static func avoidLinkIds(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: @escaping (LinkIds) -> ()) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "127.0.0.1"
        urlComponents.port = 8080
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
                print(error)
                return
            }
            completion(LinkIds(red: red, yellow: yellow))
        }.resume()
    }
    
    struct LinkIds {
        let red, yellow: [Int]
    }
}
