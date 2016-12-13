//
//  Location.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

///Stores coordinate information about location
class Location: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let coordinate: CLLocationCoordinate2D
    
    init(name: String, coordinate: CLLocationCoordinate2D) {
        if let index = name.characters.index(of: ",") {
            title = name[name.startIndex ..< index]
        } else {
            title = name
        }
        subtitle = name
        self.coordinate = coordinate
    }
}
