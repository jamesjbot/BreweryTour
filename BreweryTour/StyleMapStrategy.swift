//
//  StyleMapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/* 
    Subclass to map strategy provides annotation for Style chosen breweries
 
    This class will initial search for any breweries attached to the style 
    initialFetchBreweries
    This will also register for update to the breweries set in the Style object
    When Style is update it will fire the NSFetchedResultsDelegate that we will
    We to call a new fetch to get the whole set of update
    fetch
    sortTheLocations from the superclass.
    sendTheAnnotations back to the view controller from the superclass

 */

import Foundation
import MapKit
import CoreData

class StyleMapStrategy: MapStrategy, NSFetchedResultsControllerDelegate {

// MARK: - Constants

    // These are delays to update the mapViewController
    let initialDelay = 1000 // 1 second
    let longDelay = 10000 // 10 seconds

    let maxShortDelayLoops = 10

    // Coredata
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


// MARK: - Variables

    private var maxPoints: Int?

    var delayLoops = 0
    var bounceDelay: Int = 0

    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()

    private var debouncedFunction: (()->())? = nil


// MARK: - Functions

    init(s: Style, view: MapViewController, location: CLLocation, maxPoints points: Int) {
        super.init()
        maxPoints = points
        targetLocation = location
        breweryLocations.removeAll()
        initialFetchBreweries(byStyle: s)
        mapViewController = view
        sortLocations()
        print("Style thinks this many points \(maxPoints)")
        if breweryLocations.count > maxPoints! {
            breweryLocations = Array(breweryLocations[0..<maxPoints!])
        }
        sendAnnotationsToMap()
    }


    // Used for when style is updated with new breweries
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        breweryLocations = (controller.fetchedObjects?.first as! Style).brewerywithstyle?.allObjects as! [Brewery]
        debouncedFunction!()
    }


    // This function will drop the excessive calls to redisplay the map
    // Borrowed from
    // http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call/33794262#33794262
    private func debounce(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
        var lastFireTime = DispatchTime.now()
        let dispatchDelay = DispatchTimeInterval.milliseconds(delay)

        return {
            let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
            queue.asyncAfter(deadline: dispatchTime, execute: {
                let when: DispatchTime = lastFireTime + dispatchDelay
                let now = DispatchTime.now()
                if now.rawValue >= when.rawValue {
                    lastFireTime = DispatchTime.now()
                    action()
                }
            })
        }
    }


    func endSearch() {
        styleFRC.delegate = nil
    }


    private func fetch() {
        do {
            try styleFRC.performFetch()
            if let locations = styleFRC.fetchedObjects?.first?.brewerywithstyle?.allObjects as? [Brewery] {
                breweryLocations = locations
            }
        } catch {
            NSLog("Critical error unable to read database.")
        }
    }


    private func fetchSortandSend() {
        delayLoops += 1
        if delayLoops > maxShortDelayLoops { // After 10 run make the delay even longer
            bounceDelay = longDelay
            // Replace the debounced function with a longer version
            debouncedFunction = nil
            debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
                self.fetchSortandSend()
            })
        }
        fetch()
        sortLocations()
        if breweryLocations.count > maxPoints! {
            breweryLocations = Array(breweryLocations[0..<maxPoints!])
        }
        sendAnnotationsToMap()
    }


    // This functio is called once only during initializaiton
    private func initialFetchBreweries(byStyle: Style) {
        // Fetch all the Breweries with style
        readOnlyContext?.automaticallyMergesChangesFromParent = true
        let request : NSFetchRequest<Style> = Style.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", byStyle.id!)
        // A static view of current breweries with styles
        styleFRC = NSFetchedResultsController(fetchRequest: request ,
                                              managedObjectContext: readOnlyContext!,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        styleFRC.delegate = self

        do {
            try styleFRC.performFetch()
            breweryLocations = styleFRC.fetchedObjects?.first?.brewerywithstyle?.allObjects as! [Brewery]
        } catch {
            NSLog("Error reading coredata")
        }
        // Initialize debounce function and associate it with sortanddisplay
        bounceDelay = initialDelay
        debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
            self.fetchSortandSend()
        })
    }
}


// TODO Delete? MARK: - UpdateManagedObjectContext

//extension StyleMapStrategy: ReceiveBroadcastManagedObjectContextRefresh {
//
//    internal func contextsRefreshAllObjects() {
//        styleFRC.managedObjectContext.refreshAllObjects()
//        // We must performFetch after refreshing context, otherwise we will retain
//        // Old information is retained.
//        do {
//            try styleFRC.performFetch()
//        } catch {
//            NSLog("Error reading coredata")
//        }
//    }
//}

