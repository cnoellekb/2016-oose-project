//
//  Route.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import CoreLocation

/// Describes a route
class Route {
    /// Origination
    private let from: CLLocationCoordinate2D
    /// Destination
    private let to: CLLocationCoordinate2D
    
    var result = [String: Any]()
    
    /// Stroke color for overlay
    var color: UIColor {
        return .red
    }
    
    /// Initializes a route
    ///
    /// - Parameters:
    ///   - from: origination
    ///   - to: destination
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.from = from
        self.to = to
    }
    
    /// Builds an HTTP request for the route
    fileprivate var routingQuery: URLComponents {
        var query = URLComponents()
        query.scheme = "https"
        query.host = "open.mapquestapi.com"
        query.path = "/directions/v2/route"
        query.queryItems = [
            URLQueryItem(name: "key", value: Bundle.main.object(forInfoDictionaryKey: "MQApplicationKey") as? String),
            URLQueryItem(name: "from", value: "\(from.tuple)"),
            URLQueryItem(name: "to", value: "\(to.tuple)"),
            URLQueryItem(name: "routeType", value: "pedestrian")
        ]
        return query
    }
    
    /// Queries MapQuest server for the route
    ///
    /// - Parameter completion: called when request is completed
    func calculateRoute(completion: @escaping ([CLLocationCoordinate2D]) -> ()) {
        guard let url = routingQuery.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let route = json["route"] as? [String: Any],
                    let sessionID = route["sessionId"] as? String else {
                return
            }
            result = route
            Route.routeShape(ofSessionID: sessionID, completion: completion)
        }.resume()
    }
    
    /// Queries Mapquest for route shape
    ///
    /// - Parameters:
    ///   - id: session ID
    ///   - completion: called when request is completed
    private static func routeShape(ofSessionID id: String, completion: @escaping ([CLLocationCoordinate2D]) -> ()) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "open.mapquestapi.com"
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

/// Subclass of route for middle route
class MiddleRoute: Route {
    /// LinkIds to avoid
    private let avoidLinkIds: AvoidLinkIds
    
    /// Stroke color for overlay
    override var color: UIColor {
        return .yellow
    }
    
    /// Calls super and add constraints for middle route
    fileprivate override var routingQuery: URLComponents {
        var query = super.routingQuery
        if !avoidLinkIds.red.isEmpty {
            let linkIds = avoidLinkIds.red.map(String.init).joined(separator: ",")
            let queryItem = URLQueryItem(name: "tryAvoidLinkIds", value: linkIds)
            query.queryItems?.append(queryItem)
        }
        return query
    }
    
    /// Initializes a middle route
    ///
    /// - Parameters:
    ///   - from: origination
    ///   - to: destination
    ///   - avoidLinkIds: linkIds to avoid
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, avoidLinkIds: AvoidLinkIds) {
        self.avoidLinkIds = avoidLinkIds
        super.init(from: from, to: to)
    }
}

/// Subclass of route for safest route
class SafestRoute: Route {
    /// LinkIds to avoid
    private let avoidLinkIds: AvoidLinkIds
    
    /// Stroke color for overlay
    override var color: UIColor {
        return .green
    }
    
    /// Calls super and add constraints for safest route
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
    
    /// Initializes a safest route
    ///
    /// - Parameters:
    ///   - from: origination
    ///   - to: destination
    ///   - avoidLinkIds: linkIds to avoid
    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, avoidLinkIds: AvoidLinkIds) {
        self.avoidLinkIds = avoidLinkIds
        super.init(from: from, to: to)
    }
}

/// Holds linkIds to avoid
struct AvoidLinkIds {
    /// Worst linkIds
    let red: [Int]
    /// Bad linkIds
    let yellow: [Int]
}

extension CLLocationCoordinate2D {
    /// Converts coordinate to string for queries
    var tuple: String {
        return "\(latitude),\(longitude)"
    }
}
