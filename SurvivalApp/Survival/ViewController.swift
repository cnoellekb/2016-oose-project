//
//  ViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import MapKit

/// Main view controller with a map view
class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, StateDelegate {
    // MARK: - UI
    
    /// Main map view
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
            
            mapView.delegate = self
        }
    }
    /// Text field for origination
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
    /// Text field for destination
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
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var bottomHightConstraint: NSLayoutConstraint!
    @IBOutlet weak var showBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var hideBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Location
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestLocation()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: locations[0].coordinate, span: span)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }
    
    // MARK: - State
    
    /// Current state of operation
    private var state: State? {
        willSet {
            if let annotations = state?.annotations, !annotations.isEmpty {
                mapView.removeAnnotations(annotations)
            }
            if let overlays = state?.overlays, !overlays.isEmpty {
                mapView.removeOverlays(overlays)
            }
            var shouldLayout = false
            if showBottomConstraint.isActive {
                showBottomConstraint.isActive = false
                hideBottomConstraint.isActive = true
                shouldLayout = true
            }
            if shouldLayout {
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
            if let topVC = state?.topViewController {
                topVC.removeFromParentViewController()
                topVC.view.removeFromSuperview()
            }
            if let bottomVC = state?.bottomViewController {
                bottomVC.removeFromParentViewController()
                bottomVC.view.removeFromSuperview()
            }
        }
        didSet {
            state?.delegate = self
            var shouldLayout = false
            if let bottomSegue = state?.bottomSegue {
                performSegue(withIdentifier: bottomSegue, sender: nil)
                showBottomConstraint.isActive = true
                hideBottomConstraint.isActive = false
                shouldLayout = true
            }
            if shouldLayout {
                UIView.animate(withDuration: 0.5) {
                    self.view.layoutIfNeeded()
                }
            }
        }
    }
    
    /// Origination
    private var from: Location?
    /// Destination
    private var to: Location?
    
    /// Start a name search
    ///
    /// - Parameters:
    ///   - name: location name
    ///   - type: origination or destination
    private func search(for name: String, type: SearchingState.SearchType) {
        let topLeft = mapView.convert(.zero, toCoordinateFrom: nil)
        let bottomRight = mapView.convert(CGPoint(x: mapView.frame.width, y: mapView.frame.height), toCoordinateFrom: nil)
        state = SearchingState(name: name, topLeft: topLeft, bottomRight: bottomRight, type: type)
    }
    
    /// Start routing
    private func route() {
        guard let from = from?.coordinate ?? mapView.userLocation.location?.coordinate, let to = to?.coordinate else {
            reportError(title: "Please enter an origination", message: "Cannot get current location.")
            return
        }
        state = RoutingState(from: from, to: to)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        state?.prepare(for: segue, bottomHeight: bottomHightConstraint)
    }
    
    // MARK: - StateDelegate
    
    /// Display annotations generated by current state
    ///
    /// - Parameter annotations: array of annotations
    func didGenerate(annotations: [MKAnnotation]) {
        guard annotations.count > 0 else { return }
        mapView.addAnnotations(annotations)
        let latitudes = annotations.map { $0.coordinate.latitude }
        let longitudes = annotations.map { $0.coordinate.longitude }
        let min = CLLocationCoordinate2D(latitude: latitudes.max()!, longitude: longitudes.min()!)
        let max = CLLocationCoordinate2D(latitude: latitudes.min()!, longitude: longitudes.max()!)
        let minPoint = MKMapPointForCoordinate(min)
        let maxPoint = MKMapPointForCoordinate(max)
        let size = MKMapSize(width: maxPoint.x - minPoint.x, height: maxPoint.y - minPoint.y)
        let rect = MKMapRect(origin: minPoint, size: size)
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 200, left: 100, bottom: 250, right: 100), animated: true)
    }
    
    func select(annotation: MKAnnotation) {
        mapView.selectAnnotation(annotation, animated: true)
    }
    
    /// Display overlays generated by current state
    ///
    /// - Parameter overlays: array of overlays
    func didGenerate(overlay: MKOverlay) {
        mapView.add(overlay, level: .aboveRoads)
        mapView.setVisibleMapRect(overlay.boundingMapRect, edgePadding: UIEdgeInsets(top: 150, left: 20, bottom: 150, right: 20), animated: true)
    }
    
    /// Display an error from current state
    ///
    /// - Parameters:
    ///   - title: error title
    ///   - message: error message
    func reportError(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Text field target-actions
    
    /// Origination completed
    @IBAction func fromTextFieldDone() {
        if let text = fromTextField.text, !text.isEmpty {
            search(for: text, type: .from)
            fromTextField.resignFirstResponder()
        } else {
            toTextField.becomeFirstResponder()
        }
    }
    
    /// Origination text field loses focus
    @IBAction func fromTextFieldEnd() {
        if !(state is SearchingState) {
            if fromTextField.text?.isEmpty == true {
                from = nil
            } else {
                fromTextField.text = from?.title
            }
        }
    }
    
    /// Destination completed
    @IBAction func toTextFieldDone() {
        if let text = toTextField.text, !text.isEmpty {
            search(for: text, type: .to)
        }
        toTextField.resignFirstResponder()
    }
    
    /// Destination text field loses focus
    @IBAction func toTextFieldEnd() {
        if !(state is SearchingState) {
            toTextField.text = to?.title
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    /// Renderer for overlay
    ///
    /// - Parameters:
    ///   - mapView: source map view
    ///   - overlay: overlay to display
    /// - Returns: renderer
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
    
    /// View for annotation
    ///
    /// - Parameters:
    ///   - mapView: source map view
    ///   - annotation: annotation to display
    /// - Returns: annotation view
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let location = annotation as? Location {
            let pin = mapView.dequeueReusableAnnotationView(withIdentifier: "Pin") as? MKPinAnnotationView ?? MKPinAnnotationView(annotation: location, reuseIdentifier: "Pin")
            pin.animatesDrop = true
            pin.canShowCallout = true
            let button = UIButton(type: .detailDisclosure)
            button.setImage(#imageLiteral(resourceName: "Arrow"), for: .normal)
            pin.rightCalloutAccessoryView = button
            return pin
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let annotation = view.annotation {
            state?.didSelect(annotation: annotation)
        }
    }
    
    /// Select location
    ///
    /// - Parameters:
    ///   - mapView: source map view
    ///   - view: annotation tapped
    ///   - control: control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let search = state as? SearchingState, let location = view.annotation as? Location else {
            return
        }
        set(location: location, for: search.searchType)
    }
    
    func set(location: Location, for type: SearchingState.SearchType) {
        state = nil
        if type == .to {
            to = location
            toTextField.text = location.title
            route()
        } else {
            from = location
            fromTextField.text = location.title
        }
    }
    
    /// Maintain minimal zoom level
    ///
    /// - Parameters:
    ///   - mapView: source map view
    ///   - animated: if change is animated
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.camera.altitude < 1265.4 {
            let camera = mapView.camera
            let newCamera = MKMapCamera(lookingAtCenter: camera.centerCoordinate, fromDistance: 1265.5, pitch: camera.pitch, heading: camera.heading)
            mapView.setCamera(newCamera, animated: animated)
        }
    }
}
