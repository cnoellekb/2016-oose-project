//
//  State.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/31.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import MapKit

protocol StateDelegate: class {
    func didGenerateAnnotation(_ annotation: MKAnnotation)
}

protocol State {
    weak var delegate: StateDelegate? { get set }
    var annotations: [MKAnnotation] { get }
    func strokeColor(for annotation: MKAnnotation) -> UIColor?
}
