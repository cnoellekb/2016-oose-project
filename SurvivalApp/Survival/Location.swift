//
//  Location.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import CoreLocation

///Stores coordinate information about location
enum Location: CustomStringConvertible {
    case name(String)
    case coordinate(CLLocationCoordinate2D)
    
    var description: String {
        switch self {
        case .name(let name):
            return name
        case .coordinate(let coordinate):
            return "\(coordinate.latitude),\(coordinate.longitude)"
        }
    }
}
