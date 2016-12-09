//
//  State.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

protocol StateDelegate: class {
    func didGenerateAnnotation(_ annotation: MKAnnotation)
}

protocol State {
    weak var delegate: StateDelegate? { get set }
    var annotations: [MKAnnotation] { get }
    func strokeColor(for annotation: MKAnnotation) -> UIColor?
}
