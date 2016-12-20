//
//  Maneuver.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit
import CoreLocation

struct Maneuver {
    let narrative: String
    let distance: Double
    let streets: [String]
    let directionName: String
    let startPoint: CLLocationCoordinate2D
    let turnType: Int
    
    var turnTypeImage: UIImage? {
        return UIImage(named: "\(turnType)")
    }
}
