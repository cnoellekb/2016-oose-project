//
//  SearchResultTableViewCell.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

/// Cell of search result
class SearchResultTableViewCell: UITableViewCell {
    /// Icon image
    @IBOutlet weak var icon: UIImageView!
    /// Name label
    @IBOutlet weak var nameLabel: UILabel!
    /// Address label
    @IBOutlet weak var addressLabel: UILabel!
    /// Button background view
    @IBOutlet weak var buttonView: UIView!
    
    /// Reset button background to blue
    ///
    /// - Parameters:
    ///   - highlighted: unused
    ///   - animated: unused
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        buttonView.backgroundColor = #colorLiteral(red: 0.007406264544, green: 0.4804522395, blue: 0.99433285, alpha: 1)
    }
    
    /// Reset button background to blue
    ///
    /// - Parameters:
    ///   - selected: unused
    ///   - animated: unused
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        buttonView.backgroundColor = #colorLiteral(red: 0.007406264544, green: 0.4804522395, blue: 0.99433285, alpha: 1)
    }
}
