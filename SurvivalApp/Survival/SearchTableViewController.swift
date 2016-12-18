//
//  SearchTableViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

protocol SearchTableViewControllerDelegate: class {
    var locations: [Location] { get }
    func didTapRow(at index: Int)
    func didTapSetButton(at index: Int)
}

class SearchTableViewController: UITableViewController {
    weak var delegate: SearchTableViewControllerDelegate!
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate.locations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let location = delegate.locations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResult", for: indexPath) as! SearchResultTableViewCell
        cell.nameLabel.text = location.title
        cell.addressLabel.text = location.subtitle
        return cell
    }
    
    func select(row: Int) {
        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapRow(at: indexPath.row)
    }
    
    @IBAction func tapSetButton(_ sender: UIButton) {
        if let cell = sender.superview?.superview?.superview as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            delegate.didTapSetButton(at: indexPath.row)
        }
    }
    
    func update() {
        tableView.reloadData()
    }
}
