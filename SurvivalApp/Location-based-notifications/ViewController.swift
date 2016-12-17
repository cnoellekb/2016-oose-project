import UIKit
import UserNotifications
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var isGrantedNotificationAccess:Bool = false
    
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        //Performs any additional setup after loading the view
        super.viewDidLoad()
        
        let bttn = UIButton(frame: CGRect(x: 100, y: 200, width: 100, height: 50))
        bttn.setTitle("Schedule", for: .normal)
        bttn.setTitleColor(UIColor.gray, for: .normal)
        bttn.addTarget(self, action: #selector(ViewController.scheduleNotification), for: .touchUpInside)
        view.addSubview(bttn)
        
        setUpNotification()
        setUpLocationManager()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //Condition when status is not determined
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
        //Condition when authorization is successful
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }
    
    func setUpNotification() -> Void {
        //Shows the user an alert the first time they use the Survival app
        let options: UNAuthorizationOptions = [.alert, .sound]

    }
    
    func scheduleNotification(trigger: UNNotificationTrigger) -> Void {
        if isGrantedNotificationAccess {
            //Display notification content
            let content = UNMutableNotificationContent()
            content.title = "Warning:"
            content.body = "Entering a high crime zone area"
            content.sound = UNNotificationSound.default()
            
            //Scheduling
            let identifier = "TestNotification"
            let request = UNNotificationRequest(identifier: identifier,
                                                content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
                if let error = error {
                    //Error if something goes wrong
                    print(error)
                }
                
                
            })
        }
    }
    
    func setUpLocationManager() -> Void {
        //Sets up locationManager
        locationManager.delegate = self;
        locationManager.distanceFilter = kCLLocationAccuracyNearestTenMeters;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            
            //Region to be defined here
            
            // Region data
            let title = "Location"
            let coordinate = CLLocationCoordinate2DMake(90.0000, 0.0000)           
            let regionRadius = 300.0
            
            // Setup region
            let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: coordinate.latitude,
                                                                         longitude: coordinate.longitude), radius: regionRadius, identifier: title)
            locationManager.startMonitoring(for: region)
        }
    }
    
    

}

