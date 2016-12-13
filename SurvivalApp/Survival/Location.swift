//
//  Location.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/15.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import MapKit

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
