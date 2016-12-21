//
//  RoutingViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

/// Data source and events
protocol RoutingViewControllerDelegate: class {
    /// Data source
    var routes: [Route?] { get }
    /// Choose a route
    ///
    /// - Parameter route: chosen route
    func choose(route: Route)
    /// Report error as alert
    ///
    /// - Parameters:
    ///   - title: error title
    ///   - message: error message
    func reportError(title: String, message: String?)
}

/// Bottom view controller of RoutingState
class RoutingViewController: UIViewController {
    /// RoutingState
    weak var delegate: RoutingViewControllerDelegate?
    
    /// Time label
    @IBOutlet weak var timeLabel: UILabel!
    /// Distance label
    @IBOutlet weak var distanceLabel: UILabel!
    /// Button background view
    @IBOutlet weak var buttonView: UIView!
    /// Safety slider
    @IBOutlet weak var slider: UISlider!
    
    /// Type of route
    ///
    /// - safest: safest route
    /// - middle: middle route
    /// - fastest: fastest route
    private enum RouteType: Int {
        case safest, middle, fastest
    }
    /// Type of route
    private var routeType: RouteType? {
        didSet {
            if let type = routeType, delegate?.routes[type.rawValue] == nil {
                buttonView.backgroundColor = #colorLiteral(red: 0.7233663201, green: 0.7233663201, blue: 0.7233663201, alpha: 1)
                routeType = nil
            } else {
                buttonView.backgroundColor = #colorLiteral(red: 0.007406264544, green: 0.4804522395, blue: 0.99433285, alpha: 1)
            }
            updateLabels()
        }
    }
    
    /// Move slider to exact location
    ///
    /// - Parameter sender: slider
    @IBAction func sliderValueChange(_ sender: UISlider) {
        sender.value.round(.toNearestOrAwayFromZero)
        let value = Int(sender.value)
        if let type = RouteType(rawValue: value) {
            routeType = type
        }
    }
    
    /// User tapped on slider
    ///
    /// - Parameter sender: gesture recognizer
    @IBAction func sliderTap(_ sender: UITapGestureRecognizer) {
        let pointTapped = sender.location(in: view)
        let positionOfSlider = slider.frame.origin
        let widthOfSlider = slider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(slider.maximumValue) / widthOfSlider)
        slider.value = Float(newValue)
        sliderValueChange(slider)
    }
    
    /// Time formatter
    private let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter
    }()
    
    /// Update contents on labels
    private func updateLabels() {
        guard let index = routeType?.rawValue,
                let route = delegate?.routes[index],
                let time = route.result["time"] as? Double,
                let distance = route.result["distance"] as? Double else {
            timeLabel.text = "N/A"
            distanceLabel.text = "(N/A)"
            return
        }
        timeLabel.text = dateComponentsFormatter.string(from: time)
        distanceLabel.text = String(format: "(%.1f mi)", distance)
    }
    
    /// Receive data
    func update() {
        routeType = .safest
    }
    
    /// Start navigation
    @IBAction func start() {
        if let type = routeType, let route = delegate?.routes[type.rawValue] {
            delegate?.choose(route: route)
        }
    }
}
