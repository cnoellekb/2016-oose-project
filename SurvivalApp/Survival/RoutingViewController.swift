//
//  RoutingViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

class RoutingViewController: UIViewController {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    private enum RouteType: Int {
        case safest, middle, fastest
    }
    private var routeType = RouteType.middle
    
    @IBAction func sliderValueChange(_ sender: UISlider) {
        sender.value.round(.toNearestOrAwayFromZero)
        let value = Int(sender.value)
        if let type = RouteType(rawValue: value) {
            routeType = type
        }
    }
    
    @IBAction func sliderTap(_ sender: UITapGestureRecognizer) {
        let pointTapped = sender.location(in: view)
        let positionOfSlider = slider.frame.origin
        let widthOfSlider = slider.frame.size.width
        let newValue = ((pointTapped.x - positionOfSlider.x) * CGFloat(slider.maximumValue) / widthOfSlider)
        slider.value = Float(newValue)
        sliderValueChange(slider)
    }
    
    @IBAction func start() {
    }
}
