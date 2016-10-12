//
//  ViewController.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/5.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import UIKit
import Mapbox

class ViewController: UIViewController {
    @IBOutlet var mapView: MQMapView! {
        didSet {
            mapView.userTrackingMode = .follow
        }
    }
    @IBOutlet weak var fromTextField: UITextField! {
        didSet {
            let fromLabel = UILabel()
            fromLabel.text = "From: "
            fromLabel.font = UIFont.preferredFont(forTextStyle: .title1)
            fromLabel.sizeToFit()
            fromTextField.leftView = fromLabel
            fromTextField.leftViewMode = .always
        }
    }
    @IBOutlet weak var toTextField: UITextField! {
        didSet {
            let toLabel = UILabel()
            toLabel.text = "To: "
            toLabel.font = UIFont.preferredFont(forTextStyle: .title1)
            toLabel.sizeToFit()
            toTextField.leftView = toLabel
            toTextField.leftViewMode = .always
        }
    }
    
    @IBAction func fromTextFieldDone() {
        toTextField.becomeFirstResponder()
    }
    
    @IBAction func toTextFieldDone() {
        toTextField.resignFirstResponder()
        guard let to = toTextField.text, !to.isEmpty else {
            let alert = UIAlertController(title: "Please enter a destination", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        let from: String
        if let text = fromTextField.text, !text.isEmpty {
            from = text
        } else {
            guard let location = mapView.userLocation?.location else {
                let alert = UIAlertController(title: "Please enter an origination", message: "Cannot get current location.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            from = "\(location.coordinate.latitude),\(location.coordinate.longitude)"
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = "http"
        urlComponents.host = "www.mapquestapi.com"
        urlComponents.path = "/directions/v2/route"
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: Bundle.main.object(forInfoDictionaryKey: "MQApplicationKey") as? String),
            URLQueryItem(name: "from", value: from),
            URLQueryItem(name: "to", value: to),
        ]
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                    let route = json["route"] as? [String: Any],
                    let sessionID = route["sessionId"] as? String else {
                print(error)
                return
            }
            var urlComponents = URLComponents()
            urlComponents.scheme = "http"
            urlComponents.host = "www.mapquestapi.com"
            urlComponents.path = "/directions/v2/routeshape"
            urlComponents.queryItems = [
                URLQueryItem(name: "key", value: Bundle.main.object(forInfoDictionaryKey: "MQApplicationKey") as? String),
                URLQueryItem(name: "sessionId", value: sessionID),
                URLQueryItem(name: "fullShape", value: "\(true)"),
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
                let polyline = MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
                DispatchQueue.main.async {
                    self.mapView.add(polyline)
                }
            }.resume()
        }.resume()
    }
}
