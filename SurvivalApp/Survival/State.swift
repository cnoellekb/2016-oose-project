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
    /// Called when state wants to select an annotation
    ///
    /// - Parameter annotation: annotation to select
    func select(annotation: MKAnnotation)
    /// Called when state has generated overlays
    ///
    /// - Parameter overlays: newly generated overlays
    func didGenerate(overlay: MKOverlay)
    /// Called when state wants to choose a location
    ///
    /// - Parameters:
    ///   - location: chosen location
    ///   - type: origination or destination
    func choose(location: Location, for type: SearchingState.SearchType)
    /// Called when state wants to choose a route
    ///
    /// - Parameter route: chosen route
    func choose(route: Route)
    /// Called when state wants to end navigation
    func stopNavigation()
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
    /// System status bar color
    var preferredStatusBarStyle: UIStatusBarStyle { get }
    /// All annotations for this state
    var annotations: [MKAnnotation] { get }
    /// All overlays for this state
    var overlays: [MKOverlay] { get }
    /// Current bottom view controller of the state
    var bottomViewController: UIViewController? { get }
    /// Stroke color for overlay
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor?
    /// User did select annotation
    ///
    /// - Parameter annotation: selected annotation
    func didSelect(annotation: MKAnnotation)
    /// User moved to new location
    ///
    /// - Parameter location: updated location
    func update(location: CLLocationCoordinate2D)
    /// Should show top view controller
    var shouldShowTop: Bool { get }
    /// Bottom view controller segue name
    var bottomSegue: String? { get }
    /// Handle bottom view controller segue
    ///
    /// - Parameters:
    ///   - segue: Storyboard segue
    ///   - bottomHeight: bottom container height constraint
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint)
}

extension State {
    /// Default to black status bar
    var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    /// Default to no annotation
    var annotations: [MKAnnotation] {
        return []
    }
    /// Default to no overlay
    var overlays: [MKOverlay] {
        return []
    }
    /// Default to no bottom view controller
    var bottomViewController: UIViewController? {
        return nil
    }
    /// Default to no stroke color
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor? {
        return nil
    }
    /// Default to do nothing
    ///
    /// - Parameter annotation: unused
    func didSelect(annotation: MKAnnotation) {
    }
    /// Default to do nothing
    ///
    /// - Parameter location: unused
    func update(location: CLLocationCoordinate2D) {
    }
    /// Default to hide top container
    var shouldShowTop: Bool {
        return false
    }
    /// Default to no bottom view controller
    var bottomSegue: String? {
        return nil
    }
    /// Default to do nothing
    ///
    /// - Parameters:
    ///   - segue: unused
    ///   - bottomHeight: unused
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint) {
    }
}
