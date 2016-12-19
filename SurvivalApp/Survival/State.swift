//
//  State.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

/// Listener of state events
protocol StateDelegate: class {
    /// Called when state has generated annotations
    ///
    /// - Parameter annotations: newly generated annotations
    func didGenerate(annotations: [MKAnnotation])
    func select(annotation: MKAnnotation)
    /// Called when state has generated overlays
    ///
    /// - Parameter overlays: newly generated overlays
    func didGenerate(overlay: MKOverlay)
    func choose(location: Location, for type: SearchingState.SearchType)
    func choose(route: Route)
    /// Called when state is reporting an error
    ///
    /// - Parameters:
    ///   - title: error title
    ///   - message: error message
    func reportError(title: String, message: String?)
}

/// State of operation
protocol State {
    /// Event delegate
    weak var delegate: StateDelegate? { get set }
    /// All annotations for this state
    var annotations: [MKAnnotation] { get }
    /// All overlays for this state
    var overlays: [MKOverlay] { get }
    var topViewController: UIViewController? { get }
    var bottomViewController: UIViewController? { get }
    /// Stroke color for overlay
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor?
    func didSelect(annotation: MKAnnotation)
    var bottomSegue: String? { get }
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint)
}

extension State {
    var annotations: [MKAnnotation] {
        return []
    }
    var overlays: [MKOverlay] {
        return []
    }
    var topViewController: UIViewController? {
        return nil
    }
    var bottomViewController: UIViewController? {
        return nil
    }
    /// Default implementation of stroke color
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor? {
        return nil
    }
    func didSelect(annotation: MKAnnotation) {
    }
    var bottomSegue: String? {
        return nil
    }
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint) {
    }
}
