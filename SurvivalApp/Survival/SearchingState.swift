//
//  SearchingState.swift
//  Survival
//
//  Created by 张国晔 on 2016/11/13.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import MapKit

class SearchingState: State {
    var delegate: StateDelegate?
    var annotations: [MKAnnotation] {
        return []
    }
    var overlays: [MKOverlay] {
        return []
    }
}
