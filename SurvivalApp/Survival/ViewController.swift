//
//  ViewController.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/5.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import UIKit
import Mapbox

class ViewController: UIViewController, MGLMapViewDelegate, StateDelegate {
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
    
    private var state: State? {
        didSet {
            state?.delegate = self
        }
    }
    
    func didGenerateAnnotation(annotation: MGLAnnotation) {
        mapView.addAnnotation(annotation)
        mapView.showAnnotations(state!.annotations, animated: true)
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
        if let annotations = state?.annotations {
            mapView.removeAnnotations(annotations)
        }
        state = RoutingState(from: from, to: .name(to))
    }
    
    func mapView(_ mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        if let state = state, let color = state.strokeColor(for: annotation) {
            return color
        }
        return .blue
    }
}
