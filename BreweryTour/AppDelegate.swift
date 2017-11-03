//
//  AppDelegate.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import SwiftyBeaver

//var log = SwiftyBeaver.self

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Constants
    internal let coreDataStack = CoreDataStack.init(modelName: "BreweryTour")

    // MARK: Varaibles

    var window: UIWindow?
    var log = SwiftyBeaver.self

    let bbCreationQueue: BreweryAndBeerCreationProtocol = NewCreationQueue.sharedInstance()

    // MARK: Functions

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        checkIfFirstLaunched()

        // Dependency inject our creation queue
//        Mediator.sharedInstance().creationQueue = bbCreationQueue
//        if let tabbar = window?.rootViewController as? UITabBarController {
//            for child in tabbar.viewControllers ?? [] {
//                guard var tab = child as? AcceptsCreationQueue else {
//                    continue
//                }
//                tab.set(creationQueue: bbCreationQueue)
//            }
//        }
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

        // Save settings
        UserDefaults.standard.synchronize()
        // Save coredata
        coreDataStack?.saveToFile()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

        // Save user preferences
        UserDefaults.standard.synchronize()
        // Save coredata
        coreDataStack?.saveToFile()
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

        // Save User preferences
        UserDefaults.standard.synchronize()
        // Save coredata
        coreDataStack?.saveToFile()
    }

}


// MARK: - SwiftyBeaver Logging Implementation

extension AppDelegate {

    fileprivate func checkIfFirstLaunched() {

        setupSwiftyBeaverLogging()
        createLogEntryForPathToDocumentsDirectory()
        setTutorialsForFirstTimeRun()
    }


    private func setupSwiftyBeaverLogging() {

        deletePreviousSwiftyBeaverLogfile()
        createNewSwiftyBeaverLogfile()
    }


    private func deletePreviousSwiftyBeaverLogfile() {

        let fileManager = FileManager.default
        let cachedirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        var swiftybeaverPath = cachedirectory[0].appendingPathComponent("swiftybeaver")
        swiftybeaverPath = swiftybeaverPath.appendingPathExtension("log")
        try? fileManager.removeItem(at: swiftybeaverPath)
    }


    private func createNewSwiftyBeaverLogfile() {
        // FIXME:
        print("createNewSwiftyBeaverLogfile() called")
        let file = FileDestination()
        file.format = "$DEEEE MMMM dd yyyy HH:mm:sss$d $L: $M: "
        log.addDestination(file)
        SwiftyBeaver.info("Starting New Run.....")
        log.info("HI")

        //platform.minLevel = .warning
    }


    private func createLogEntryForPathToDocumentsDirectory() {
        #if arch(i386) || arch(x86_64)
            if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
                print("Documents Directory: \(documentsPath)")
                SwiftyBeaver.info("Documents Directory: \(documentsPath)")
            }
        #endif
    }
}

// MARK: - 
// MARK: Tutorial Persistance

extension AppDelegate {

    fileprivate func setTutorialsForFirstTimeRun() {
        guard UserDefaults.standard.object(forKey: g_constants.FirstTimeLaunched) == nil else {
            return
        }
        // Mark all the tutorial as being viewed..
        UserDefaults.standard.set(false, forKey: g_constants.FirstTimeLaunched)
        UserDefaults.standard.set(true, forKey: g_constants.CategoryViewShowTutorial)
        UserDefaults.standard.set(true, forKey: g_constants.MapViewShowTutorial)
        UserDefaults.standard.set(true, forKey: g_constants.SelectedBeersShowTutorial)
        UserDefaults.standard.set(true, forKey: g_constants.FavoriteBeersShowTutorial)
        UserDefaults.standard.set(true, forKey: g_constants.FavoriteBreweriesShowTutorial)
    }
    
}

