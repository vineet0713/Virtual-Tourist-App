//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let centerAmericaLat: Float = 39.8283
    let centerAmericaLong: Float = -98.5795
    
    // sets the latitudinal and longitudinal distances (for setting map region)
    let defaultLatitudeDelta: Float = 5000000   // represents 5 million meters, or 5 thousand kilometers
    let defaultLongitudeDelta: Float = 5000000  // represents 5 million meters, or 5 thousand kilometers
    
    func checkIfFirstLaunch() {
        if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") == false {
            print("This is the first launch ever!")
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            
            UserDefaults.standard.set(centerAmericaLat, forKey: "Region Center Latitude")
            UserDefaults.standard.set(centerAmericaLong, forKey: "Region Center Longitude")
            UserDefaults.standard.set(defaultLatitudeDelta, forKey: "Region Span Latitude Delta")
            UserDefaults.standard.set(defaultLongitudeDelta, forKey: "Region Span Longitude Delta")
            
            UserDefaults.standard.synchronize()
        }
    }


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        checkIfFirstLaunch()
        DataController.sharedInstance().load()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
    }

}

