import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }


    func applicationWillResignActive(_ application: UIApplication) {
        //Sent when the application is in the process of changing from an active to inactive state, for example, during temporary interruptions (e.g an incoming text message, notification, or phone call), when the user leaves the application, transitioning to a standby/background state.
        //We can use if/when pausing any ongoing applications or tasks, disabling timers, and invalidating graphics rendering callbacks, if needed. 
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //Used to save user data. release shared resources, invalidate timers, store app. state information to restore app to its current state in the event it's terminated later. 
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        //Called as a part of the transition when moving from background operation to active operation. Here changes made on entering the background can be undone 

    }

}
