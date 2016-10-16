//
//  Location.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/15.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import CoreLocation

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
