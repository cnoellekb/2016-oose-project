//
//  ViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import MapKit

extension Notification.Name {
    static let openURL = Notification.Name("OpenURL")
}

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
    weak var topViewController: NavigatingTopViewController!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var bottomHightConstraint: NSLayoutConstraint!
    @IBOutlet weak var showTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var hideTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var showBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var hideBottomConstraint: NSLayoutConstraint!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return state?.preferredStatusBarStyle ?? .default
    }
    
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
        
        NotificationCenter.default.addObserver(forName: .openURL, object: nil, queue: nil) {
            let numberFormatter = NumberFormatter()
            if let dict = $0.userInfo,
                    let from = dict["from"] as? String,
                    let to = dict["to"] as? String,
                    let fromLatString = dict["fromLat"] as? String,
                    let toLatString = dict["toLat"] as? String,
                    let fromLngString = dict["fromLng"] as? String,
                    let toLngString = dict["toLng"] as? String,
                    let fromLat = numberFormatter.number(from: fromLatString)?.doubleValue,
                    let toLat = numberFormatter.number(from: toLatString)?.doubleValue,
                    let fromLng = numberFormatter.number(from: fromLngString)?.doubleValue,
                    let toLng = numberFormatter.number(from: toLngString)?.doubleValue {
                self.fromTextField.text = from
                self.toTextField.text = to
                self.from = Location(address: from, coordinate: CLLocationCoordinate2D(latitude: fromLat, longitude: fromLng))
                self.to = Location(address: to, coordinate: CLLocationCoordinate2D(latitude: toLat, longitude: toLng))
                self.route()
            }
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
    
    #if DEMO
    private let simulatedUserLocation = SimulatedUserLocation()
    #endif
    
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
            if showTopConstraint.isActive {
                showTopConstraint.isActive = false
                hideTopConstraint.isActive = true
                shouldLayout = true
            }
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
            if let bottomVC = state?.bottomViewController {
                bottomVC.removeFromParentViewController()
                bottomVC.view.removeFromSuperview()
            }
        }
        didSet {
            state?.delegate = self
            var shouldLayout = false
            if state?.shouldShowTop == true {
                showTopConstraint.isActive = true
                hideTopConstraint.isActive = false
                shouldLayout = true
            }
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
            setNeedsStatusBarAppearanceUpdate()
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
        if let routingState = RoutingState(from: from, to: to) {
            state = routingState
        } else {
            reportError(title: "Are you seriously going to walk this far?", message: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dst = segue.destination as? NavigatingTopViewController {
            topViewController = dst
        } else {
            state?.prepare(for: segue, bottomHeight: bottomHightConstraint)
        }
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
    
    func choose(location: Location, for type: SearchingState.SearchType) {
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
    
    func choose(route: Route) {
        guard let currentLocation = mapView.userLocation.location?.coordinate else { return }
        state = NavigatingState(route: route, topViewController: topViewController, currentLocation: currentLocation)
        #if DEMO
            mapView.showsUserLocation = false
            moveSimulatedUserLocation(along: route)
            mapView.addAnnotation(simulatedUserLocation)
        #else
            mapView.setUserTrackingMode(.follow, animated: true)
        #endif
    }
    
    #if DEMO
    private var timer: Timer?
    
    private func moveSimulatedUserLocation(along route: Route) {
        guard let start = route.shape.first else { return }
        simulatedUserLocation.coordinate = start
        var index = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
            if index >= route.shape.count - 1 {
                $0.invalidate()
                return
            }
            var now = self.simulatedUserLocation.coordinate
            var move = 10.0
            repeat {
                let end = route.shape[index + 1]
                let distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(now), MKMapPointForCoordinate(end))
                if (distance <= move) {
                    move -= distance
                    now = end
                    index += 1
                    if index == route.shape.count - 1 {
                        break
                    }
                } else {
                    let k = move / distance
                    let latitude = (end.latitude - now.latitude) * k + now.latitude
                    let longitude = (end.longitude - now.longitude) * k + now.longitude
                    now = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    move = 0
                }
            } while move > 0
            self.simulatedUserLocation.coordinate = now
            self.mapView.setCenter(now, animated: true)
            self.state?.update(location: now)
        }
    }
    #endif
    
    func stopNavigation() {
        state = nil
        #if DEMO
            timer?.invalidate()
            mapView.removeAnnotation(simulatedUserLocation)
            mapView.showsUserLocation = true
        #endif
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
        choose(location: location, for: search.searchType)
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
    
    #if !DEMO
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        state?.update(location: userLocation.coordinate)
    }
    #endif
}

#if DEMO
private class SimulatedUserLocation: MKUserLocation {
    private var simulatedCoordinate = CLLocationCoordinate2D(latitude: 39, longitude: -76)
    override dynamic var coordinate: CLLocationCoordinate2D {
        get {
            return simulatedCoordinate
        }
        set {
            simulatedCoordinate = newValue
        }
    }
}
#endif
