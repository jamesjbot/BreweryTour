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


enum DelaysConstants: Int {

    // These are delays used to slow down updates from the background model to
    // presentation in the mapViewController
    case InitialDelay = 1000 // 1 second
    case LongDelay = 100000 // 10 seconds
    case MaximumShortDelayLoops = 3
}


// MARK: -

protocol FetchableStrategy: MappableStrategy, NSFetchedResultsControllerDelegate {

    // MARK: Stored Properties

    var readOnlyContext: NSManagedObjectContext? { get set }

    var runningID: Int { get set }

    var bounceDelay: Int { get }

    var delayedBlockFetchSortSend: (()->())? { get set }

    var delayLoops: Int { get set }

    var maxPoints: Int? { get set }

    var breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>? { get set }


    // MARK: Functions


    // MARK: Function signatures implemented in the Protocol Extension

    func createFetchRequestResultsControllerAndRegisterAsDelegate(with style: Style?) -> NSFetchedResultsController<NSFetchRequestResult>
    func performFetchAndReturnUnsortedBreweries(on breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery]


    // MARK: Function signatures implemented in the Concrete Class

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    func createFetchRequest(with style: Style?) -> NSFetchRequest<NSFetchRequestResult>
    func concreteClassGetBreweries(from breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery]
}


// MARK: -

extension FetchableStrategy {

    // MARK: FetchableStrategy Protocol Extension Implementations

    internal func createFetchRequestResultsControllerAndRegisterAsDelegate(with style: Style? = nil) -> NSFetchedResultsController<NSFetchRequestResult> {

        let request: NSFetchRequest<NSFetchRequestResult>? = createFetchRequest(with: style)

        breweryOrStyleUpdateController = NSFetchedResultsController(fetchRequest: request! ,
                                                      managedObjectContext: readOnlyContext!,
                                                      sectionNameKeyPath: nil,
                                                      cacheName: nil)
        breweryOrStyleUpdateController?.delegate = self

        return breweryOrStyleUpdateController!
    }


    /// MapStrategy method to return the breweries currently fetched by the fetched results controller.
    internal func getBreweries() -> [Brewery] {
        return performFetchAndReturnUnsortedBreweries(on: breweryOrStyleUpdateController!)
    }


    internal func performFetchAndReturnUnsortedBreweries(on breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery] {

        SwiftyBeaver.info("\(#file).\(#function) called")

        var breweryLocations: [Brewery] = []
        do {
            try breweryOrStyleUpdateController.performFetch()
            breweryLocations = concreteClassGetBreweries(from: breweryOrStyleUpdateController)
        } catch {
            SwiftyBeaver.error("\(#file) \(#function) Critical error unable to read database.")
        }
        return breweryLocations
    }


    // MARK: MapAnnotationProvider Implementation

    internal func endSearch() -> (()->())? {
        SwiftyBeaver.info("FetchableMapStrategy endSearch called")
        delayedBlockFetchSortSend = nil
        return delayedBlockFetchSortSend
    }


    // MARK: Helper Functions

    fileprivate func limitReturned(breweries: [Brewery], to maxPoints: Int) -> [Brewery] {

        var breweryLocations = breweries
        if breweryLocations.count > maxPoints {
            breweryLocations = Array(breweryLocations[0..<maxPoints])
        }
        return breweryLocations
    }


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
            guard self?.delayedBlockFetchSortSend != nil else {
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


    /// Fetches from the NSFetchedResultsController
    /// uses the save map strategy for processing
    /// then sends the annotation to the MapAnnotationReceiver for processing
    internal func fetchSortandSendAnnotations(from: NSFetchedResultsController<NSFetchRequestResult>,
                                              with localCurrentMapStrategy: Int,
                                              to: MapAnnotationReceiver) -> Bool {

        SwiftyBeaver.info("Fetchable Map Strategy, fetchSortAndSendAnnotations called()")
        // Only the last created strategy is allow to run
        guard Mediator.sharedInstance().onlyValidStyleStrategy == localCurrentMapStrategy else {
            let _ = endSearch()
            return false
        }

        let breweries: [Brewery] = sortLocations(performFetchAndReturnUnsortedBreweries(on: breweryOrStyleUpdateController!))!

        send(annotations: convertBreweryToAnnotation(breweries: breweries),
             to: parentMapViewController!)

        return true
    }


    fileprivate func wrapUpFetchSortAndSendForDelayedExecutionInClassScopeVariable(afterDelay bounceDelay: Int )
        -> (()->())? {

            let action = {
                SwiftyBeaver.info("Embedded fetchSortAndSend() action from wrapUp Functions\(#line)")
                let _ = self.fetchSortandSendAnnotations(from: self.breweryOrStyleUpdateController!,
                                                         with: self.runningID,
                                                         to: self.parentMapViewController!)
            }

            delayedBlockFetchSortSend = delayFiring(function: action, afterDelay: bounceDelay, fromQueue: DispatchQueue.main)

            return delayedBlockFetchSortSend
    }
}


// MARK: -

/// Concrete class to that will constantly update whatever MapAnnotationReceiver
/// is attached to it.
final class StyleMapStrategy: NSObject, FetchableStrategy {

    // MARK: Variables

    var runningID: Int = 0
    var parentMapViewController: MapAnnotationReceiver?
    var targetLocation: CLLocation?
    var readOnlyContext: NSManagedObjectContext?
    var bounceDelay: Int = DelaysConstants.InitialDelay.rawValue
    var delayedBlockFetchSortSend: (()->())?
    var delayLoops: Int = DelaysConstants.MaximumShortDelayLoops.rawValue
    var maxPoints: Int?
    var breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>?


    // MARK: Functions

    convenience init(style: Style?,
                     view: MapAnnotationReceiver,
                     location: CLLocation,
                     maxPoints points: Int,
                     inputContext: NSManagedObjectContext) {

        self.init(view: view)
        readOnlyContext = inputContext
        runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        parentMapViewController = view

        SwiftyBeaver.info("StyleMapStrategy calling sortLocations in initialization")

        let breweries = initialFetchBreweries(byStyle: style)

        let _ = fetchSortandSendAnnotations(from: breweryOrStyleUpdateController!,
                                            with: runningID,
                                            to: parentMapViewController!)

        // FIXME can I get sortandsend together and seperate out fetch

        var breweryLocations = sortLocations(breweries)

        breweryLocations = limitReturned(breweries: breweryLocations!, to: maxPoints!)

        send(annotations: convertBreweryToAnnotation(breweries: breweryLocations!), to: parentMapViewController!)

    }


    // This is the implemented template method from Fetchable Strategy
    // it returns breweries based on a Style (StyleMapStrategy)
    func concreteClassGetBreweries(from breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery] {

        // Reaching into the Style entry and extracting the breweries that are attached to the specified style
        try? breweryOrStyleUpdateController.performFetch()
        return ((breweryOrStyleUpdateController.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery])!
    }


    func createFetchRequest(with style: Style?) -> NSFetchRequest<NSFetchRequestResult> {

        // Fetch all the Breweries with style
        let request : NSFetchRequest<Style> = Style.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", (style?.id!)!)
        return request as! NSFetchRequest<NSFetchRequestResult>
    }


    // FIXME should this be initialiation
    /// This function is called once only during initialization.
    internal func initialFetchBreweries(byStyle: Style?) -> [Brewery] {

        let controller = createFetchRequestResultsControllerAndRegisterAsDelegate(with: byStyle)

        let _ = wrapUpFetchSortAndSendForDelayedExecutionInClassScopeVariable(afterDelay: bounceDelay)

        return performFetchAndReturnUnsortedBreweries(on: controller)
    }


    // MARK: Updating function

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        SwiftyBeaver.info("FetchableMapStrategy controllerDidChangeContent called, next calling debounced function")
        delayedBlockFetchSortSend?()
    }

}


// MARK: -

final class AllBreweriesMapStrategy: NSObject, FetchableStrategy {

    // MARK: Variables

    var runningID: Int = 0
    var parentMapViewController: MapAnnotationReceiver?
    var targetLocation: CLLocation?
    var readOnlyContext: NSManagedObjectContext?
    var bounceDelay: Int = DelaysConstants.InitialDelay.rawValue
    var delayedBlockFetchSortSend: (()->())?
    var delayLoops: Int = DelaysConstants.MaximumShortDelayLoops.rawValue
    var maxPoints: Int?
    var breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>?


    // MARK: Functions

    convenience init(view: MapAnnotationReceiver,
                     location: CLLocation,
                     maxPoints points: Int,
                     inputContext: NSManagedObjectContext) {
        self.init(view: view)
        readOnlyContext = inputContext
        runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        parentMapViewController = view
        SwiftyBeaver.info("AllBreweriesMapStrategy calling sortLocations in initialization.")

        var breweryLocations = sortLocations(initialFetchBreweries())!

        breweryLocations = limitReturned(breweries: breweryLocations, to: maxPoints!)

        send(annotations: convertBreweryToAnnotation(breweries: breweryLocations),
             to: parentMapViewController!)
    }


    // Retrieve brewery from the populated NSFetchedResultsController
    func concreteClassGetBreweries(from breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery] {

        try? breweryOrStyleUpdateController.performFetch()
        return (breweryOrStyleUpdateController.fetchedObjects as? [Brewery])!
    }


    func createFetchRequest(with style: Style?) -> NSFetchRequest<NSFetchRequestResult> {
        // Fetch all breweries regardless of style
        let request : NSFetchRequest<Brewery> = Brewery.fetchRequest()
        request.sortDescriptors = []
        return request as! NSFetchRequest<NSFetchRequestResult>
    }


    // This function is called once only during initializaiton
    internal func initialFetchBreweries() -> [Brewery] {

        // Fetch all breweries unfilted by style
        let controller = createFetchRequestResultsControllerAndRegisterAsDelegate(with: nil)

        // Initialize debounce function and associate it with latter display

        let _ = wrapUpFetchSortAndSendForDelayedExecutionInClassScopeVariable(afterDelay: bounceDelay)

        return performFetchAndReturnUnsortedBreweries(on: controller)
    }


    // MARK: Updating function
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        SwiftyBeaver.info("FetchableMapStrategy controllerDidChangeContent called, next calling debounced function")
        delayedBlockFetchSortSend?()
    }
}














