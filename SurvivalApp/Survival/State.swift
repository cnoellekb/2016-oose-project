//
//  State.swift
//  Survival
//
//  Created by 张国晔 on 2016/10/31.
//  Copyright © 2016年 Johns Hopkins University. All rights reserved.
//

import MapKit

protocol StateDelegate: class {
    func didGenerateAnnotations(_ annotations: [MKAnnotation])
    func didGenerateOverlays(_ overlays: [MKOverlay])
    func reportError(title: String, message: String?)
}

protocol State {
    weak var delegate: StateDelegate? { get set }
    var annotations: [MKAnnotation] { get }
    var overlays: [MKOverlay] { get }
    func strokeColor(for annotation: MKAnnotation) -> UIColor?
}

extension State {
    func strokeColor(for annotation: MKAnnotation) -> UIColor? {
        return nil
    }
}
