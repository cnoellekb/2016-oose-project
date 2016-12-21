//
//  NavigatingBottomViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

protocol NavigatingBottomViewControllerDelegate: class {
    var isMuted: Bool { get set }
    func updateViews()
    func stopNavigation()
}

class NavigatingBottomViewController: UIViewController {
    weak var delegate: NavigatingBottomViewControllerDelegate?
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var muteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate?.updateViews()
        updateImage()
    }
    
    @IBAction func mute() {
        if let delegate = delegate {
            delegate.isMuted = !delegate.isMuted
            updateImage()
        }
    }
    
    @IBAction func stop() {
        let alert = UIAlertController(title: "Stop navigation?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Stop", style: .destructive) { _ in
            self.delegate?.stopNavigation()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func updateImage() {
        muteButton.isSelected = delegate?.isMuted ?? false
    }
}
