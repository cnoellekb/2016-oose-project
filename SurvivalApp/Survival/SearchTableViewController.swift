//
//  SearchTableViewController.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import UIKit

/// Data source and events
protocol SearchTableViewControllerDelegate: class {
    /// Data source
    var locations: [Location] { get }
    /// User tapped table view row
    ///
    /// - Parameter index: index of row
    func didTapRow(at index: Int)
    /// User tapped set button on table view row
    ///
    /// - Parameter index: index of row
    func didTapSetButton(at index: Int)
}

/// Bottom view controller of SearchingState
class SearchTableViewController: UITableViewController {
    /// SearchingState
    weak var delegate: SearchTableViewControllerDelegate!
    
    /// Number of section is 1
    ///
    /// - Parameter tableView: table view
    /// - Returns: 1
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Number of rows is the location count
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - section: 0
    /// - Returns: location count
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate.locations.count
    }
    
    /// Dequeue and setup cell
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path of cell
    /// - Returns: cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let location = delegate.locations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResult", for: indexPath) as! SearchResultTableViewCell
        cell.nameLabel.text = location.title
        cell.addressLabel.text = location.subtitle
        return cell
    }
    
    /// Select row in table view
    ///
    /// - Parameter row: index of row
    func select(row: Int) {
        tableView.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .middle)
    }
    
    /// User tapped table view row
    ///
    /// - Parameters:
    ///   - tableView: table view
    ///   - indexPath: index path of cell
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didTapRow(at: indexPath.row)
    }
    
    /// User tapped set button
    ///
    /// - Parameter sender: set button
    @IBAction func tapSetButton(_ sender: UIButton) {
        if let cell = sender.superview?.superview?.superview as? UITableViewCell, let indexPath = tableView.indexPath(for: cell) {
            delegate.didTapSetButton(at: indexPath.row)
        }
    }
    
    /// Received data
    func update() {
        tableView.reloadData()
    }
}
