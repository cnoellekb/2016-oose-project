//
//  ViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import MapKit

///Generates UI and visual for users
class ViewController: UIViewController, MKMapViewDelegate, StateDelegate {
    @IBOutlet var mapView: MKMapView! {
        didSet {
            let osmOverlay = MKTileOverlay(urlTemplate: "https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png")
            osmOverlay.maximumZ = 18
            osmOverlay.canReplaceMapContent = true
            mapView.add(osmOverlay, level: .aboveRoads)
            
            let overlay = MKTileOverlay(urlTemplate: "http://127.0.0.1:8080/v1/heatmap/{x}-{y}-{z}.png")
            overlay.maximumZ = 14
            mapView.add(overlay, level: .aboveLabels)
            
            mapView.mapType = .satellite
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
    
    func didGenerateAnnotation(_ annotation: MKAnnotation) {
        if let overlay = annotation as? MKOverlay {
            mapView.add(overlay, level: .aboveRoads)
            mapView.setVisibleMapRect(mapView.mapRectThatFits(overlay.boundingMapRect), edgePadding: UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5), animated: true)
        } else {
            mapView.addAnnotation(annotation)
            mapView.showAnnotations(state!.annotations, animated: true)
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
        let from: Location
        if let text = fromTextField.text, !text.isEmpty {
            from = .name(text)
        } else {
            guard let location = mapView.userLocation.location else {
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
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = state?.strokeColor(for: polyline)?.withAlphaComponent(0.5)
            renderer.lineWidth = 2
            return renderer
        }
        if let tile = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tile)
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}
