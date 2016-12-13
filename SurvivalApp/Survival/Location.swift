//
//  Location.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

/// Name and coordinate of a location
class Location: NSObject, MKAnnotation {
    /// Name
    let title: String?
    /// Full address
    let subtitle: String?
    /// Coordinate
    let coordinate: CLLocationCoordinate2D
    
    /// Initializes a Location with an address and a coordinate. First part of the address is extracted as its name.
    ///
    /// - Parameters:
    ///   - name: full address
    ///   - coordinate: coordinate
    init(address: String, coordinate: CLLocationCoordinate2D) {
        if let index = address.characters.index(of: ",") {
            title = address[address.startIndex ..< index]
        } else {
            title = address
        }
        subtitle = address
        self.coordinate = coordinate
    }
}
