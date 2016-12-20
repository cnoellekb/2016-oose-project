//
//  SearchResultTableViewCell.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

class SearchResultTableViewCell: UITableViewCell {
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var buttonView: UIView!
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        buttonView.backgroundColor = #colorLiteral(red: 0.007406264544, green: 0.4804522395, blue: 0.99433285, alpha: 1)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        buttonView.backgroundColor = #colorLiteral(red: 0.007406264544, green: 0.4804522395, blue: 0.99433285, alpha: 1)
    }
}
