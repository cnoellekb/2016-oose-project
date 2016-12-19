//
//  SearchingState.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit

/// State of searching
class SearchingState: State, SearchTableViewControllerDelegate {
    /// Event delegate
    var delegate: StateDelegate?
    /// All annotations generated here
    var annotations: [MKAnnotation] {
        return locations
    }
    
    /// Type of search
    ///
    /// - from: origination search
    /// - to: destination search
    enum SearchType {
        case from, to
    }
    /// Type of search
    var searchType: SearchType
    
    /// Results of search
    var locations = [Location]()
    
    var index = 0
    
    /// Search for location by name
    ///
    /// - Parameters:
    ///   - name: location name
    ///   - topLeft: top left of search bounding box (nil for global search)
    ///   - bottomRight: bottom right of search bounding box (nil for global search)
    ///   - completion: called when request is completed
    private func search(for name: String, topLeft: CLLocationCoordinate2D?, bottomRight: CLLocationCoordinate2D?, completion: @escaping ([Location]) -> ()) {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "nominatim.openstreetmap.org"
        urlComponents.path = "/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "countrycodes", value: "US"),
            URLQueryItem(name: "limit", value: "\(10)")
        ]
        if let topLeft = topLeft, let bottomRight = bottomRight {
            urlComponents.queryItems?.append(URLQueryItem(name: "viewbox", value: "\(topLeft.longitude),\(topLeft.latitude),\(bottomRight.longitude),\(bottomRight.latitude)"))
            urlComponents.queryItems?.append(URLQueryItem(name: "bounded", value: "\(1)"))
        }
        guard let url = urlComponents.url else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                    let json = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else {
                DispatchQueue.main.async {
                    self.delegate?.reportError(title: "Failed to search", message: error?.localizedDescription)
                }
                return
            }
            let numberFormatter = NumberFormatter()
            let locations: [Location] = json.flatMap {
                guard let address = $0["display_name"] as? String,
                        let latitudeString = $0["lat"] as? String,
                        let latitude = numberFormatter.number(from: latitudeString)?.doubleValue,
                        let longitudeString = $0["lon"] as? String,
                        let longitude = numberFormatter.number(from: longitudeString)?.doubleValue else {
                    return nil
                }
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                return Location(address: address, coordinate: coordinate)
            }
            completion(locations)
        }.resume()
    }
    
    /// Initializes searching state and starts a name search. First search within a bounding box, if it fails, start a global search.
    ///
    /// - Parameters:
    ///   - name: location name
    ///   - topLeft: top left of search bounding box
    ///   - bottomRight: bottom right of search bounding box
    ///   - type: origination or destination
    init(name: String, topLeft: CLLocationCoordinate2D, bottomRight: CLLocationCoordinate2D, type: SearchType) {
        searchType = type
        search(for: name, topLeft: topLeft, bottomRight: bottomRight) { result in
            if result.isEmpty {
                self.search(for: name, topLeft: nil, bottomRight: nil) { result in
                    DispatchQueue.main.async {
                        if result.isEmpty {
                            self.delegate?.reportError(title: "No result", message: nil)
                        } else {
                            self.handle(result: result)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.handle(result: result)
                }
            }
        }
    }
    
    private func handle(result: [Location]) {
        locations = result
        searchTableViewController?.update()
        delegate?.didGenerate(annotations: locations)
        delegate?.select(annotation: locations[0])
    }
    
    private weak var searchTableViewController: SearchTableViewController?
    var bottomViewController: UIViewController? {
        return searchTableViewController
    }
    
    var bottomSegue: String? {
        return "Search"
    }
    
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint) {
        if let dst = segue.destination as? SearchTableViewController {
            bottomHeight.constant = dst.preferredContentSize.height
            searchTableViewController = dst
            dst.delegate = self
        }
    }
    
    func didTapRow(at index: Int) {
        delegate?.select(annotation: locations[index])
    }
    
    func didTapSetButton(at index: Int) {
        delegate?.set(location: locations[index], for: searchType)
    }
    
    func didSelect(annotation: MKAnnotation) {
        if let location = annotation as? Location, let index = locations.index(of: location) {
            searchTableViewController?.select(row: index)
        }
    }
}
