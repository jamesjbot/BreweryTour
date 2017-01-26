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

//TODO REMOVE IN FINAL protocol FetchableMapStrategy: MapStrategy, NSFetchedResultsControllerDelegate {
//
//    // MARK: - Constants
//
//    // These are delays to update the mapViewController
////    let initialDelay: Int
////    let longDelay: Int
////
////    let maxShortDelayLoops: Int
////    internal var runningID: Int?
////
////    // Coredata
////    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
////    let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext
////
////
////    // MARK: - Variables
////
////    internal var bounceDelay: Int = 0
////    internal var debouncedFunction: (()->())? = nil
////
////    private var delayLoops = 0
////    fileprivate var maxPoints: Int?
////
////    fileprivate var styleFRC: NSFetchedResultsController<NSFetchRequestResult>?
//
//
//    // MARK: - Functions
//
//    // Used for when style is updated with new breweries
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
//    // This function will drop the excessive calls to redisplay the map
//    // Borrowed from
//    // http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call/33794262#33794262
//    func debounce(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->()
//    func fetch()
//    func fetchSortandSend()
//}

class FetchableMapStrategy: MapStrategy, NSFetchedResultsControllerDelegate  {

    // MARK: - Constants

    // These are delays to update the mapViewController
    internal let initialDelay = 1000 // 1 second
    private let longDelay = 10000 // 10 seconds

    private let maxShortDelayLoops = 3

    internal var runningID: Int?

    // Coredata
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: - Variables

    internal var bounceDelay: Int = 0
    internal var debouncedFunction: (()->())? = nil

    private var delayLoops = 0
    fileprivate var maxPoints: Int?

    fileprivate var styleFRC: NSFetchedResultsController<NSFetchRequestResult>?


    // MARK: - Functions

    // Used for when style is updated with new breweries
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        print("Fetchable Map Strategy controller did change content called")
        debouncedFunction!()
    }


    // This function will drop the excessive calls to redisplay the map
    // Borrowed from
    // http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call/33794262#33794262
    internal func debounce(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
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


    override func endSearch() {
        debouncedFunction = nil
        styleFRC?.delegate = nil
    }


    internal func fetch() {
        fatalError("You must override fetch()")
    }


    internal func fetchSortandSend() {
        // Only the last created strategy is allow to run
        guard Mediator.sharedInstance().onlyValidStyleStrategy == runningID else {
            endSearch()
            return
        }

//        delayLoops += 1
//        if delayLoops > maxShortDelayLoops { // After 10 run make the delay even longer
//            bounceDelay = longDelay
//            // Replace the debounced function with a longer version
//            debouncedFunction = nil
//            debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
//                self.fetchSortandSend()
//            })
//        }
        fetch()
        sortLocations()
//        if breweryLocations.count > maxPoints! {
//            breweryLocations = Array(breweryLocations[0..<maxPoints!])
//        }
        sendAnnotationsToMap()
    }

}


class StyleMapStrategy: FetchableMapStrategy {

    init(s: Style?, view: MapViewController, location: CLLocation, maxPoints points: Int) {
        super.init()
        runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        breweryLocations.removeAll()
        initialFetchBreweries(byStyle: s)
        parentMapViewController = view
        sortLocations()
        if breweryLocations.count > maxPoints! {
            breweryLocations = Array(breweryLocations[0..<maxPoints!])
        }
        sendAnnotationsToMap()
    }

    override internal func fetch() {
        do {
            try styleFRC?.performFetch()
            if let locations = (styleFRC?.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery] {
                breweryLocations = locations
            }
        } catch {
            NSLog("Critical error unable to read database.")
        }
    }


    // This functio is called once only during initializaiton
    internal func initialFetchBreweries(byStyle: Style?) {
        // Fetch all the Breweries with style
        readOnlyContext?.automaticallyMergesChangesFromParent = true
        let request : NSFetchRequest<Style> = Style.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", (byStyle?.id!)!)
        // A static view of current breweries with styles
        styleFRC = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> ,
                                              managedObjectContext: readOnlyContext!,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        styleFRC?.delegate = self

        do {
            try styleFRC?.performFetch()
            breweryLocations = (styleFRC?.fetchedObjects?.first as! Style).brewerywithstyle?.allObjects as! [Brewery]
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


class AllBreweriesMapStrategy: FetchableMapStrategy {

//    override func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
//        print("all breweries map strategy controllerDid change content")
//        super.controllerDidChangeContent(controller)
//    }

    override internal func fetch() {
        do {
            try styleFRC?.performFetch()
            if let locations = styleFRC?.fetchedObjects as? [Brewery] {
                breweryLocations = locations
            }
        } catch {
            NSLog("Critical error unable to read database.")
        }
    }

    // This functio is called once only during initializaiton
    internal func initialFetchBreweries() {
        // Fetch all the Breweries with style
        readOnlyContext?.automaticallyMergesChangesFromParent = true
        let request : NSFetchRequest<Brewery> = Brewery.fetchRequest()
        request.sortDescriptors = []
        // A static view of current breweries with styles
        styleFRC = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> ,
                                              managedObjectContext: readOnlyContext!,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        styleFRC?.delegate = self

        do {
            try styleFRC?.performFetch()
            if let locations: [Brewery] = styleFRC?.fetchedObjects as? [Brewery] {
                breweryLocations = locations
            }
        } catch {
            NSLog("Error reading coredata")
        }
        // Initialize debounce function and associate it with sortanddisplay
        bounceDelay = initialDelay
        debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
            self.fetchSortandSend()
        })
    }

    init(view: MapViewController, location: CLLocation, maxPoints points: Int) {
        super.init()
        runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        breweryLocations.removeAll()
        initialFetchBreweries()
        parentMapViewController = view
        sortLocations()
        if breweryLocations.count > maxPoints! {
            breweryLocations = Array(breweryLocations[0..<maxPoints!])
        }
        sendAnnotationsToMap()
    }
}
