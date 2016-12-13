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
    var annotations = [MKAnnotation]()
    var overlays: [MKOverlay] {
        return []
    }
    
    init(name: String, topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "nominatim.openstreetmap.org"
        urlComponents.path = "/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "countrycodes", value: "US"),
            URLQueryItem(name: "viewbox", value: "\(topLeft.longitude),\(topLeft.latitude),\(bottomRight.longitude),\(bottomRight.latitude)"),
            URLQueryItem(name: "bounded", value: "\(1)"),
            URLQueryItem(name: "limit", value: "\(10)")
        ]
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
            self.annotations = json.flatMap {
                guard let latitudeString = $0["lat"] as? String,
                        let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
                        let longitudeString = $0["lon"] as? String,
                        let longitude = numberFormatter.number(from: longitudeString)?.doubleValue else {
                    return nil
                }
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                return annotation
            }
            DispatchQueue.main.async {
                if self.annotations.isEmpty {
                    self.delegate?.reportError(title: "No result", message: nil)
                } else {
                    self.delegate?.didGenerateAnnotations(self.annotations)
                }
            }
        }.resume()
    }
}
