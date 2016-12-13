//
//  State.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

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
