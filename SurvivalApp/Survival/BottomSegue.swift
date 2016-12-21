//
//  BottomSegue.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

/// Replace bottom view controller of main view controller
class BottomSegue: UIStoryboardSegue {
    /// Perform the segue
    override func perform() {
        let vc = source as! ViewController
        vc.addChildViewController(destination)
        vc.bottomContainer.addSubview(destination.view)
        destination.view.frame = vc.bottomContainer.bounds
        destination.didMove(toParentViewController: vc)
    }
}
