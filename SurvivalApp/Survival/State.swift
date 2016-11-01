//
//  State.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/31.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import Mapbox

protocol StateDelegate: class {
    func didGenerateAnnotation(annotation: MGLAnnotation)
}

protocol State {
    weak var delegate: StateDelegate? { get set }
    var annotations: [MGLAnnotation] { get }
    func strokeColor(for annotation: MGLAnnotation) -> UIColor?
}
