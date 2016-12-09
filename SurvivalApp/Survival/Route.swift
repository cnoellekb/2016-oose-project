//
//  Route.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import CoreLocation

class Route {
    private let from, to: Location
    
    var color: UIColor {
        return .red
    }
    
    init(from: Location, to: Location) {
        self.from = from
        self.to = to
    }
    
    /**
    Builds an http request for the route.
    */
    fileprivate var routingQuery: URLComponents {
        var query = URLComponents()
        query.scheme = "http"
        query.host = "www.mapquestapi.com"
        query.path = "/directions/v2/route"
        query.queryItems = [
            URLQueryItem(name: "key", value: Bundle.main.object(forInfoDictionaryKey: "MQApplicationKey") as? String),
            URLQueryItem(name: "from", value: "\(from)"),
            URLQueryItem(name: "to", value: "\(to)"),
            URLQueryItem(name: "routeType", value: "pedestrian")
        ]
        return query
    }
    
    /**
    Takes a query and queries Mapquest server for route 
    */
    func calculateRoute(completion: @escaping ([CLLocationCoordinate2D]) -> ()) {
        guard let url = routingQuery.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let route = json["route"] as? [String: Any],
                    let sessionID = route["sessionId"] as? String else {
                return
            }
            Route.routeShape(ofSessionID: sessionID, completion: completion)
        }.resume()
    }
    
    /**
    Queries Mapquest for route shape. 
    */
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
}
/**
Subclass of route - determines safest route, overrides routing query.
*/
class SafestRoute: Route {
    private let avoidLinkIds: AvoidLinkIds
    
    override var color: UIColor {
        return .green
    }
    
    fileprivate override var routingQuery: URLComponents {
        var query = super.routingQuery
        if !avoidLinkIds.red.isEmpty {
            let linkIds = avoidLinkIds.red.map(String.init).joined(separator: ",")
            let queryItem = URLQueryItem(name: "mustAvoidLinkIds", value: linkIds)
            query.queryItems?.append(queryItem)
        }
        if !avoidLinkIds.yellow.isEmpty {
            let linkIds = avoidLinkIds.yellow.map(String.init).joined(separator: ",")
            let queryItem = URLQueryItem(name: "tryAvoidLinkIds", value: linkIds)
            query.queryItems?.append(queryItem)
        }
        return query
    }
    
    init(from: Location, to: Location, avoidLinkIds: AvoidLinkIds) {
        self.avoidLinkIds = avoidLinkIds
        super.init(from: from, to: to)
    }
}
/**
Subclass of route - determines middle route, overrides routing query.
*/
class MiddleRoute: Route {
    private let avoidLinkIds: AvoidLinkIds
    
    override var color: UIColor {
        return .yellow
    }
    
    fileprivate override var routingQuery: URLComponents {
        var query = super.routingQuery
        if !avoidLinkIds.red.isEmpty {
            let linkIds = avoidLinkIds.red.map(String.init).joined(separator: ",")
            let queryItem = URLQueryItem(name: "tryAvoidLinkIds", value: linkIds)
            query.queryItems?.append(queryItem)
        }
        return query
    }
    
    init(from: Location, to: Location, avoidLinkIds: AvoidLinkIds) {
        self.avoidLinkIds = avoidLinkIds
        super.init(from: from, to: to)
    }
}

struct AvoidLinkIds {
    let red, yellow: [Int]
}
