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
            
            if let url = server.url {
                let overlay = MKTileOverlay(urlTemplate: "\(url)/v1/heatmap/{x}-{y}-{z}.png")
                overlay.maximumZ = 12
                mapView.add(overlay, level: .aboveLabels)
            }
            
            mapView.mapType = .satellite
            mapView.delegate = self
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
        willSet {
            if let annotations = state?.annotations, !annotations.isEmpty {
                mapView.removeAnnotations(annotations)
            }
            if let overlays = state?.overlays, !overlays.isEmpty {
                mapView.removeOverlays(overlays)
            }
        }
        didSet {
            state?.delegate = self
        }
    }
    
    private var from, to: Location?
    
    private func search(for name: String, type: SearchingState.SearchType) {
        let topLeft = mapView.convert(.zero, toCoordinateFrom: nil)
        let bottomRight = mapView.convert(CGPoint(x: mapView.frame.width, y: mapView.frame.height), toCoordinateFrom: nil)
        state = SearchingState(name: name, topLeft: topLeft, bottomRight: bottomRight, type: type)
    }
    
    private func route() {
        guard let from = from?.coordinate ?? mapView.userLocation.location?.coordinate, let to = to?.coordinate else {
            reportError(title: "Please enter an origination", message: "Cannot get current location.")
            return
        }
        state = RoutingState(from: from, to: to)
    }
    
    func didGenerateAnnotations(_ annotations: [MKAnnotation]) {
        guard annotations.count > 0 else { return }
        mapView.showAnnotations(annotations, animated: true)
    }
    
    func didGenerateOverlays(_ overlays: [MKOverlay]) {
        guard overlays.count > 0 else { return }
        mapView.addOverlays(overlays, level: .aboveRoads)
        let rect = overlays.dropFirst().reduce(overlays[0].boundingMapRect) { MKMapRectUnion($0, $1.boundingMapRect) }
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 150, left: 20, bottom: 20, right: 20), animated: true)
    }
    
    func reportError(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func fromTextFieldDone() {
        if let text = fromTextField.text, !text.isEmpty, text != from?.title {
            search(for: text, type: .from)
            fromTextField.resignFirstResponder()
        } else {
            toTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func fromTextFieldEnd() {
        if !(state is SearchingState) {
            if fromTextField.text?.isEmpty == true {
                from = nil
            } else {
                fromTextField.text = from?.title
            }
        }
    }
    
    @IBAction func toTextFieldDone() {
        if let text = toTextField.text, !text.isEmpty {
            if text != to?.title {
                search(for: text, type: .to)
            } else {
                route()
            }
        }
        toTextField.resignFirstResponder()
    }
    
    @IBAction func toTextFieldEnd() {
        if !(state is SearchingState) {
            toTextField.text = to?.title
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = state?.strokeColor(for: polyline)?.withAlphaComponent(0.5)
            renderer.lineWidth = 5
            return renderer
        }
        if let tile = overlay as? MKTileOverlay {
            return MKTileOverlayRenderer(tileOverlay: tile)
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let location = annotation as? Location {
            let pin = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: location, reuseIdentifier: "Pin")
            pin.animatesDrop = true
            pin.canShowCallout = true
            pin.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            return pin
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let search = state as? SearchingState, let location = view.annotation as? Location else {
            return
        }
        state = nil
        if search.searchType == .to {
            to = location
            toTextField.text = location.title
            route()
        } else {
            from = location
            fromTextField.text = location.title
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.camera.altitude < 1265.4 {
            let camera = mapView.camera
            let newCamera = MKMapCamera(lookingAtCenter: camera.centerCoordinate, fromDistance: 1265.5, pitch: camera.pitch, heading: camera.heading)
            mapView.setCamera(newCamera, animated: true)
        }
    }
}
