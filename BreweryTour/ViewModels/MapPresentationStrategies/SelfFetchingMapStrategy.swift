//
//  StyleMapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/*
 This is the style mapping algorithm, it provides map annotations for breweries
 with the currently selected beer style.

 Overview:
 This file contains both the parent class and the concrete subclasses for a 
 MapStrategy that can be fetched from Coredata.
 
 On initialization of the subclasses a search for any breweries that conform to
 the algorithm's filter is performed. This occurs in the method
 initialFetchBreweries
 
 This will also register this object for updates to the breweries set in the Style object
 When Style is updated it will fire the NSFetchedResultsDelegate that we will
 We to call a new fetch to get the whole set of update fetch
 sortTheLocations from the superclass.
 sendTheAnnotations back to the view controller from the superclass

 */

import Foundation
import MapKit
import CoreData
import SwiftyBeaver


protocol FetchableStrategy {
    func fetch() -> [Brewery]
}

protocol CoreDataStackAccess {
    // The access to the database has to be interuptable.
    // I have to be able to inject a fake CoreDataStack.
    // So what functions do I need.

    // This object should NOT know what to do with ManagedObject Context

    // The coredata stack should know what to do with a managed object context.

    //func getReadOnlyContext()
    func fetchThis(request: NSFetchRequest<NSFetchRequestResult>) -> NSFetchedResultsController<NSFetchRequestResult>
}

class FetchableMapStrategy: MapStrategy, FetchableStrategy  {

    // MARK: - Constants

    // These are delays used to slow down updates from the background model to 
    // presentation in the mapViewController
    internal let initialDelay = 1000 // 1 second
    private let longDelay = 10000 // 10 seconds

    private let maxShortDelayLoops = 3

    internal var runningID: Int?

    // Coredata
    //fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    var readOnlyContext: NSManagedObjectContext?
    // = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: - Variables

    internal var bounceDelay: Int = 0
    internal var debouncedFunction: (()->())? = nil

    private var delayLoops = 0
    fileprivate var maxPoints: Int?

    fileprivate var styleFRC: NSFetchedResultsController<NSFetchRequestResult>?


    // MARK: - Functions

    // This function will drop the excessive calls to redisplay the map
    // Borrowed from
    // http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call/33794262#33794262
    /// This function creates a timer and runs a function after a delayed amount of time
    ///
    /// - parameters:
    ///     - action: the function to fire when the time is up
    ///     - delay: amount of time to delay in milliseconds
    ///     - queue: the dispatchqueue to run the timer on
    /// - returns:
    ///     - a function block.
    fileprivate func delayFiring(function action: @escaping (()->()),
                              afterDelay delay: Int,
                              fromQueue queue: DispatchQueue) -> ()->() {

        let dispatchTime: DispatchTime = DispatchTime.now() + DispatchTimeInterval.milliseconds(delay)

        let dispatchWorkItem = createDispatchWorkItem(with: action, at: dispatchTime)

        return {queue.asyncAfter(deadline: dispatchTime,
                                 execute: dispatchWorkItem)
        }
    }
    

    internal func fetch() -> [Brewery] {
        fatalError("You must override fetch()")
    }


    internal func fetchSortandSend() {
        SwiftyBeaver.info("Fetchable Map Strategy, fetchSortAndSend called()")
        // Only the last created strategy is allow to run
        guard Mediator.sharedInstance().onlyValidStyleStrategy == runningID else {
            endSearch()
            return
        }
        fetch() // Breweries.

        sortLocations() // Sort Brewery By Distance to our location.

        sendAnnotationsToMap() // Send the newly created annotations to the map.
    }


    override internal func endSearch() {
        SwiftyBeaver.info("FetchableMapStrategy endSearch called")
        // Do we stil want this?  
        //debouncedFunction = nil
    }

}


extension FetchableMapStrategy: NSFetchedResultsControllerDelegate {

    // Used for when fetch results controller is updated with new breweries
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        SwiftyBeaver.info("FetchableMapStrategy controllerDidChangeContent called, next calling debounced function")
        debouncedFunction?()
    }
}


extension FetchableMapStrategy {

    /// Creates a DispatchWorkItem containing the command to sort brewerlocation and send it to the viewcontroller
    ///
    /// - parameters:
    ///     - action: the method to run, here it will be fetchSortAndSend
    /// - returns:
    ///     - a DispatchWorkItem
    fileprivate func createDispatchWorkItem(with action: @escaping (()->()) ,at targetTime: DispatchTime) -> DispatchWorkItem {
        return DispatchWorkItem(block: { [ weak self ] in
            // If the debounced function has been cancelled don't do anything
            SwiftyBeaver.info("Debounced DispatchWorkItem has been called")
            guard self?.debouncedFunction != nil else {
                SwiftyBeaver.info("Debounced function has been cancelled")
                return
            }
            SwiftyBeaver.info("Within the work block DispatchWorkItem")
            let timeNow = DispatchTime.now()
            if timeNow.rawValue >= targetTime.rawValue {
                action()
            }
        })
    }

    fileprivate func wrapUpFetchSortAndSendForDelayedExecutionInClassScopeVariable(afterDelay bounceDelay: Int ) {

        let action = {
            SwiftyBeaver.info("Embedded fetchSortAndSend() action from wrapUp Functions\(#line)")
            self.fetchSortandSend()
        }

        debouncedFunction = delayFiring(function: action, afterDelay: bounceDelay, fromQueue: DispatchQueue.main)
    }
}


class StyleMapStrategy: FetchableMapStrategy {

    init(s: Style?, view: MapAnnotationReceiver, location: CLLocation, maxPoints points: Int, inputContext: NSManagedObjectContext) {
        super.init(view: view)
        readOnlyContext = inputContext
        runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        super.breweryLocations.removeAll()
        initialFetchBreweries(byStyle: s)
        parentMapViewController = view as! MapAnnotationReceiver
        SwiftyBeaver.info("StyleMapStrategy calling sortLocations in initialization")
        sortLocations()
        if breweryLocations.count > maxPoints! {
            breweryLocations = Array(breweryLocations[0..<maxPoints!])
        }
        sendAnnotationsToMap()
    }

    override internal func fetch() -> [Brewery] {
        SwiftyBeaver.info("StyleMapStrategy.fetch() called")
        // Important this fixed the error 
        // Because we reinitialie it to nothing 
        // before we go to grab new entries.
        // If we don't reinitilize this will contain references to the CoreData objects and will still keep processing but when tryng access the data we will have null pointer exceptions.
        // DRY
        breweryLocations = []
        do {
            try styleFRC?.performFetch()
            if let locations = (styleFRC?.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery] {
                breweryLocations = locations
                SwiftyBeaver.info("StyleMapStrategy successfully found breweries")
            } else {
                SwiftyBeaver.info("StyleMapStrategy did not find breweries")
            }
        } catch {
            SwiftyBeaver.error("StyleMapStrategy \(#line) Critical error unable to read database.")
        }
        return breweryLocations
    }


    // This function is called once only during initialization.
    internal func initialFetchBreweries(byStyle: Style?) {
        // Fetch all the Breweries with style
        //readOnlyContext?.automaticallyMergesChangesFromParent = true
        let request : NSFetchRequest<Style> = Style.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", (byStyle?.id!)!)
        // A static view of current breweries with styles

        // From coredata I want a context 
        // so I can ultimately create an NSFetchedResultsController of which I can set myself as a delegate.

        styleFRC = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> ,
                                              managedObjectContext: readOnlyContext!,
                                              sectionNameKeyPath: nil,
                                              cacheName: nil)
        styleFRC?.delegate = self

        do {
            try styleFRC?.performFetch()
            if let locations = ((styleFRC?.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery]) {
                breweryLocations = locations
            }
        } catch {
            SwiftyBeaver.error("Error reading coredata")
        }
        // Initialize debounce function and associate it with sortanddisplay
        wrapUpFetchSortAndSendForDelayedExecutionInClassScopeVariable(afterDelay: initialDelay)
    }
}


class AllBreweriesMapStrategy: FetchableMapStrategy {

    override internal func fetch() -> [Brewery] {
        breweryLocations = []
        do {
            try styleFRC?.performFetch()
            if let locations = styleFRC?.fetchedObjects as? [Brewery] {
                breweryLocations = locations
                SwiftyBeaver.info("AllBreweriesMapStrategy successfully found breweries")
            } else {
                SwiftyBeaver.info("AllBreweriesMapStrategy did not find any breweries")
            }
        } catch {
            SwiftyBeaver.error("AllBreweriesMapStrategy Critical error unable to read database.")
        }
        return breweryLocations
    }


    // This function is called once only during initializaiton
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
            SwiftyBeaver.error("Error reading coredata")
        }
        // Initialize debounce function and associate it with sortanddisplay
        wrapUpFetchSortAndSendForDelayedExecutionInClassScopeVariable(afterDelay: initialDelay)
    }

    init(view: MapAnnotationReceiver, location: CLLocation, maxPoints points: Int,
         inputContext: NSManagedObjectContext) {
        super.init(view: view)
        readOnlyContext = inputContext
        runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        breweryLocations.removeAll()
        initialFetchBreweries()
        parentMapViewController = view
        SwiftyBeaver.info("AllBreweriesMapStrategy calling sortLocations in initialization.")
        sortLocations()
        if breweryLocations.count > maxPoints! {
            breweryLocations = Array(breweryLocations[0..<maxPoints!])
        }
        sendAnnotationsToMap()
    }
}
