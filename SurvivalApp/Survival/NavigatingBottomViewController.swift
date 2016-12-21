//
//  NavigatingBottomViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

/// Data source and events
protocol NavigatingBottomViewControllerDelegate: class {
    /// Voice is muted or not
    var isMuted: Bool { get set }
    /// Update views
    func updateViews()
    /// Stop navigation
    func stopNavigation()
}

/// Bottom view controller of NavigatingState
class NavigatingBottomViewController: UIViewController {
    /// NavigatingState
    weak var delegate: NavigatingBottomViewControllerDelegate?
    
    /// Full time label
    @IBOutlet weak var timeLabel: UILabel!
    /// Full distance label
    @IBOutlet weak var distanceLabel: UILabel!
    /// Mute button
    @IBOutlet weak var muteButton: UIButton!
    
    /// View has been loaded
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate?.updateViews()
        updateImage()
    }
    
    /// Change mute status
    @IBAction func mute() {
        if let delegate = delegate {
            delegate.isMuted = !delegate.isMuted
            updateImage()
        }
    }
    
    /// Stop navigation
    @IBAction func stop() {
        let alert = UIAlertController(title: "Stop navigation?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stop", style: .destructive) { _ in
            self.delegate?.stopNavigation()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    /// Update mute button image
    private func updateImage() {
        muteButton.isSelected = delegate?.isMuted ?? false
    }
}
