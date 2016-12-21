//
//  NavigatingState.swift
//  Survival
//
//  OOSE JHU 2016 Project
//  Guoye Zhang, Channing Kimble-Brown, Neha Kulkarni, Jeana Yee, Qiang Zhang

import MapKit
import AVFoundation

/// State of navigating
class NavigatingState: State, NavigatingBottomViewControllerDelegate {
    /// Event delegate
    weak var delegate: StateDelegate? {
        didSet {
            let polyline = MKPolyline(coordinates: route.shape, count: route.shape.count)
            overlays = [polyline]
            delegate?.didGenerate(overlay: polyline)
        }
    }
    
    /// All overlays generated here
    var overlays = [MKOverlay]()
    
    /// White status bar
    var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    /// Stroke color for overlay
    ///
    /// - Parameter overlay: overlay to display
    /// - Returns: color
    func strokeColor(for overlay: MKOverlay) -> UIColor? {
        return #colorLiteral(red: 0.01680417731, green: 0.1983509958, blue: 1, alpha: 1)
    }
    
    /// Route to navigate
    private var route: Route
    /// Maneuvers of route
    private var maneuvers: [Maneuver]
    /// Full time
    private var fullTime: Double
    /// Full distance
    private var fullDistance: Double
    /// Remaining distance by maneuvers
    private var remainingDistance: Double
    /// Current maneuver
    private var currentManeuverIndex = 0
    /// Current location
    private var currentLocation: CLLocationCoordinate2D
    /// Voice is muted or not
    var isMuted: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "mute")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "mute")
            if newValue {
                speechSynthesizer.stopSpeaking(at: .immediate)
            }
        }
    }
    
    /// Initializes navigating state and start navigation
    ///
    /// - Parameters:
    ///   - route: route to navigate
    ///   - topViewController: top view controller to display
    ///   - currentLocation: current user location
    init(route: Route, topViewController: NavigatingTopViewController, currentLocation: CLLocationCoordinate2D) {
        self.route = route
        fullTime = route.result["time"] as? Double ?? 0
        fullDistance = route.result["distance"] as? Double ?? 0
        maneuvers = (((route.result["legs"] as? [Any])?[0] as? [String: Any])?["maneuvers"] as? [[String: Any]])?.flatMap {
            if let narrative = $0["narrative"] as? String,
                    let distance = $0["distance"] as? Double,
                    let streets = $0["streets"] as? [String],
                    let directionName = $0["directionName"] as? String,
                    let startPoint = $0["startPoint"] as? [String: Double],
                    let latitude = startPoint["lat"],
                    let longitude = startPoint["lng"],
                    let turnType = $0["turnType"] as? Int {
                return Maneuver(narrative: narrative, distance: distance, streets: streets, directionName: directionName, startPoint: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), turnType: turnType)
            }
            return nil
        } ?? [Maneuver(narrative: "", distance: 0, streets: [], directionName: "", startPoint: CLLocationCoordinate2D(latitude: 0, longitude: 0), turnType: 0)]
        remainingDistance = fullDistance - maneuvers[0].distance
        navigatingTopViewController = topViewController
        self.currentLocation = currentLocation
        speak(sentence: maneuvers[0].narrative)
    }
    
    /// Should show top view controller
    var shouldShowTop: Bool {
        return true
    }
    
    /// User moved to new location
    ///
    /// - Parameter location: updated location
    func update(location: CLLocationCoordinate2D) {
        currentLocation = location
        updateViews()
    }
    
    /// Speech synthesizer for voice navigation
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    /// Speak a sentence
    ///
    /// - Parameter sentence: sentence to speak
    private func speak(sentence: String) {
        if !isMuted {
            var sentence = sentence
            if sentence.hasSuffix(" (See map for details).") {
                sentence.removeSubrange(sentence.index(sentence.endIndex, offsetBy: -23)..<sentence.endIndex)
            }
            sentence = sentence.replacingOccurrences(of: " Ln ", with: " Link ")
            sentence = sentence.replacingOccurrences(of: " Ln.", with: " Link.")
            if sentence.hasSuffix(" Ln") {
                sentence.removeSubrange(sentence.index(sentence.endIndex, offsetBy: -1)..<sentence.endIndex)
                sentence += "ink"
            }
            sentence = sentence.replacingOccurrences(of: " E ", with: " East ")
            sentence = sentence.replacingOccurrences(of: " W ", with: " West ")
            sentence = sentence.replacingOccurrences(of: " S ", with: " South ")
            sentence = sentence.replacingOccurrences(of: " N ", with: " North ")
            if sentence.hasPrefix("E ") {
                sentence.removeSubrange(sentence.startIndex...sentence.startIndex)
                sentence = "East" + sentence
            }
            if sentence.hasPrefix("W ") {
                sentence.removeSubrange(sentence.startIndex...sentence.startIndex)
                sentence = "West" + sentence
            }
            if sentence.hasPrefix("S ") {
                sentence.removeSubrange(sentence.startIndex...sentence.startIndex)
                sentence = "South" + sentence
            }
            if sentence.hasPrefix("N ") {
                sentence.removeSubrange(sentence.startIndex...sentence.startIndex)
                sentence = "North" + sentence
            }
            let utterance = AVSpeechUtterance(string: sentence)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.stopSpeaking(at: .word)
            speechSynthesizer.speak(utterance)
        }
    }
    
    /// Top view controller
    private weak var navigatingTopViewController: NavigatingTopViewController?
    /// Bottom view controller
    private weak var navigatingBottomViewController: NavigatingBottomViewController?
    /// Bottom view controller for State protocol
    var bottomViewController: UIViewController? {
        return navigatingBottomViewController
    }
    
    /// Bottom view controller segue name
    var bottomSegue: String? {
        return "Navigate"
    }
    
    /// Handle bottom view controller segue
    ///
    /// - Parameters:
    ///   - segue: Storyboard segue
    ///   - bottomHeight: bottom container height constraint
    func prepare(for segue: UIStoryboardSegue, bottomHeight: NSLayoutConstraint) {
        if let dst = segue.destination as? NavigatingBottomViewController {
            bottomHeight.constant = dst.preferredContentSize.height
            navigatingBottomViewController = dst
            dst.delegate = self
        }
    }
    
    /// Stop navigation
    func stopNavigation() {
        delegate?.stopNavigation()
    }
    
    /// Distance formatter
    private let distanceFormatter: MKDistanceFormatter = {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter
    }()
    /// Time formatter
    private let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter
    }()
    
    /// Update labels and images
    func updateViews() {
        let next = currentManeuverIndex == maneuvers.count - 1 ? route.shape.last! : maneuvers[currentManeuverIndex + 1].startPoint
        let distance = MKMetersBetweenMapPoints(MKMapPointForCoordinate(currentLocation), MKMapPointForCoordinate(next))
        let remainingDistance = self.remainingDistance * 1609.344 + distance
        if distance < 10 {
            currentManeuverIndex += 1
            if currentManeuverIndex == maneuvers.count {
                speak(sentence: "You have arrived at your destination")
                delegate?.stopNavigation()
                return
            } else {
                self.remainingDistance -= maneuvers[currentManeuverIndex].distance
                speak(sentence: maneuvers[currentManeuverIndex].narrative)
            }
        }
        let maneuver = maneuvers[currentManeuverIndex]
        navigatingTopViewController?.turnSignImageView.image = maneuver.turnTypeImage
        navigatingTopViewController?.directionLabel.text = maneuver.directionName
        navigatingTopViewController?.distanceLabel.text = distanceFormatter.string(fromDistance: distance)
        navigatingTopViewController?.streetsLabel.text = maneuver.streets.dropFirst().reduce(maneuver.streets.first) { "\($0) / \($1)" }
        navigatingBottomViewController?.distanceLabel.text = distanceFormatter.string(fromDistance: remainingDistance)
        navigatingBottomViewController?.timeLabel.text = dateComponentsFormatter.string(from: remainingDistance / (fullDistance * 1609.344) * fullTime)
    }
}
