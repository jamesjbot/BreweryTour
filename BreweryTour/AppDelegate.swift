//
//  AppDelegate.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let coreDataStack = CoreDataStack.init(modelName: "BreweryTour")
    
    func checkIfFirstLaunched() {
        if UserDefaults.standard.bool(forKey: g_constants.FirstLaunched) {
            // Do nothing
        } else {
            UserDefaults.standard.set(true, forKey: g_constants.FirstLaunched)
            UserDefaults.standard.set(true, forKey: g_constants.CategoryViewTutorial)
            UserDefaults.standard.set(true, forKey: g_constants.MapViewTutorial)
            UserDefaults.standard.set(true, forKey: g_constants.SelectedBeersTutorial)
            UserDefaults.standard.set(true, forKey: g_constants.FavoriteBeersTutorial)
            UserDefaults.standard.set(true, forKey: g_constants.FavoriteBreweriesTutorial)
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        checkIfFirstLaunched()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("applicationWillResignActive called")
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        UserDefaults.standard.synchronize()
        do {
            try coreDataStack?.saveToFile()
        } catch {
            fatalError("Error saving to coredata.")
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("applicationDidEnterBackground called")
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        // Save user preferences
        UserDefaults.standard.synchronize()
        do {
            try coreDataStack?.saveToFile()
        } catch {
            fatalError("Error saving to coredata.")
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("applicationWillTerminate called.")
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        //self.saveContext()
        // Save User preferences
        UserDefaults.standard.synchronize()
        do {
            try coreDataStack?.saveToFile()
        } catch {
            fatalError("Error saving to coredata.")
        }
    }

}

