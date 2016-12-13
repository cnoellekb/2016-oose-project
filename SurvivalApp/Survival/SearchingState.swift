//
//  SearchingState.swift
//  Survival
//
//  Created by 张国晔 on 2016/11/13.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import MapKit

class SearchingState: State {
    var delegate: StateDelegate?
    var annotations: [MKAnnotation] {
        return locations
    }
    var overlays: [MKOverlay] {
        return []
    }
    
    enum SearchType {
        case from, to
    }
    var searchType: SearchType
    
    private var locations = [Location]()
    
    private func search(for name: String, topLeft: CLLocationCoordinate2D?, bottomRight: CLLocationCoordinate2D?, completion: @escaping ([Location]) -> ()) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "nominatim.openstreetmap.org"
        urlComponents.path = "/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "countrycodes", value: "US"),
            URLQueryItem(name: "limit", value: "\(10)")
        ]
        if let topLeft = topLeft, let bottomRight = bottomRight {
            urlComponents.queryItems?.append(URLQueryItem(name: "viewbox", value: "\(topLeft.longitude),\(topLeft.latitude),\(bottomRight.longitude),\(bottomRight.latitude)"))
            urlComponents.queryItems?.append(URLQueryItem(name: "bounded", value: "\(1)"))
        }
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
                DispatchQueue.main.async {
                    self.delegate?.reportError(title: "Failed to search", message: error?.localizedDescription)
                }
                return
            }
            let numberFormatter = NumberFormatter()
            let locations: [Location] = json.flatMap {
                guard let name = $0["display_name"] as? String,
                        let latitudeString = $0["lat"] as? String,
                        let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
                        let longitudeString = $0["lon"] as? String,
                        let longitude = numberFormatter.number(from: longitudeString)?.doubleValue else {
                    return nil
                }
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                return Location(name: name, coordinate: coordinate)
            }
            completion(locations)
        }.resume()
    }
    
    init(name: String, topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, type: SearchType) {
        searchType = type
        search(for: name, topLeft: topLeft, bottomRight: bottomRight) { result in
            if result.isEmpty {
                self.search(for: name, topLeft: nil, bottomRight: nil) { result in
                    DispatchQueue.main.async {
                        if result.isEmpty {
                            self.delegate?.reportError(title: "No result", message: nil)
                        } else {
                            self.locations = result
                            self.delegate?.didGenerateAnnotations(self.locations)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.locations = result
                    self.delegate?.didGenerateAnnotations(self.locations)
                }
            }
        }
    }
}
