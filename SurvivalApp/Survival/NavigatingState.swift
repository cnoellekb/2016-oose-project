//
//  NavigatingState.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

class NavigatingState: State, NavigatingBottomViewControllerDelegate {
    /// Event delegate
    weak var delegate: StateDelegate? {
        didSet {
            let polyline = MKPolyline(coordinates: route.shape, count: route.shape.count)
            overlays = [polyline]
            delegate?.didGenerate(overlay: polyline)
        }
    }
    
    var overlays = [MKOverlay]()
    
    var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    /// Stroke color for overlay
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor? {
        return #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    
    var route: Route
    var maneuvers: [Maneuver]
    
    init(route: Route, topViewController: NavigatingTopViewController) {
        self.route = route
        maneuvers = (route.result["maneuvers"] as? [[String: Any]])?.flatMap {
            if let narrative = $0["narrative"] as? String,
                    let distance = $0["distance"] as? Double,
                    let streets = $0["streets"] as? [String],
                    let directionName = $0["directionName"] as? String,
                    let startPoint = $0["startPoint"] as? [String: Double],
                    let latitude = startPoint["lat"],
                    let longitude = startPoint["png"],
                    let turnType = $0["turnType"] as? Int {
                return Maneuver(narrative: narrative, distance: distance, streets: streets, directionName: directionName, startPoint: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), turnType: turnType)
            }
            return nil
        } ?? []
        navigatingTopViewController = topViewController
    }
    
    var shouldShowTop: Bool {
        return true
    }
    
    private weak var navigatingTopViewController: NavigatingTopViewController?
    private weak var navigatingBottomViewController: NavigatingBottomViewController?
    var bottomViewController: UIViewController? {
        return navigatingBottomViewController
    }
    
    var bottomSegue: String? {
        return "Navigate"
    }
    
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint) {
        if let dst = segue.destination as? NavigatingBottomViewController {
            bottomHeight.constant = dst.preferredContentSize.height
            navigatingBottomViewController = dst
            dst.delegate = self
        }
    }
    
    func stopNavigation() {
        delegate?.stopNavigation()
    }
}
