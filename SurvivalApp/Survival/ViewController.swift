//
//  ViewController.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/5.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import UIKit
import Mapbox

class ViewController: UIViewController, MGLMapViewDelegate {
    @IBOutlet var mapView: MQMapView! {
        didSet {
            mapView.delegate = self
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
    
    private weak var fastestRoute, safestRoute: MGLPolyline?
    
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
        let from: Location
        if let text = fromTextField.text, !text.isEmpty {
            from = .name(text)
        } else {
            guard let location = mapView.userLocation?.location else {
                let alert = UIAlertController(title: "Please enter an origination", message: "Cannot get current location.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
            from = .coordinate(location.coordinate)
        }
        mapView.remove([safestRoute, fastestRoute].flatMap { $0 } )
        Route(from: from, to: .name(to)).calculateRoute {
            var coordinates = $0
            let polyline = MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
            self.fastestRoute = polyline
            self.mapView.add(polyline)
            self.mapView.showAnnotations([polyline], animated: true)
            if let fromPoint = coordinates.first, let toPoint = coordinates.last {
                Route.avoidLinkIds(from: fromPoint, to: toPoint) {
                    Route(from: from, to: .name(to)).calculateRoute(mustAvoid: $0.red, tryAvoid: $0.yellow) { var coordinates = $0
                        let polyline = MGLPolyline(coordinates: &coordinates, count: UInt(coordinates.count))
                        self.safestRoute = polyline
                        self.mapView.add(polyline)
                    }
                }
            }
        }
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if annotation == fastestRoute { return .red }
        if annotation == safestRoute { return .green }
        return .blue
    }
}
