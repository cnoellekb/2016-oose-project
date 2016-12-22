//
//  Maneuver.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import CoreLocation

/// Maneuver on route
struct Maneuver {
    /// Sentence to speak
    let narrative: String
    /// Distance
    let distance: Double
    /// Next streets
    let streets: [String]
    /// Name of direction
    let directionName: String
    /// Staring point
    let startPoint: CLLocationCoordinate2D
    /// Type of turn (for image)
    let turnType: Int
    
    /// Image for turn type
    var turnTypeImage: UIImage? {
        return UIImage(named: "\(turnType)")
    }
}
