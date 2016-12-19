//
//  NavigatingState.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

class NavigatingState: State {
    /// Event delegate
    weak var delegate: StateDelegate? {
        didSet {
            let polyline = MKPolyline(coordinates: route.shape, count: route.shape.count)
            delegate?.didGenerate(overlay: polyline)
        }
    }
    
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
    
    init(route: Route) {
        self.route = route
    }
    
    var shouldShowTop: Bool {
        return true
    }
}
