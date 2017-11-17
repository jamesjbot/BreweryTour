//
//  SelfFetchingMapStrategyProtocol.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/*

 The new logic is to get annotations populated, then Bond will take care of the notifications

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
 eventually call a new fetch to get the whole set of updated fetched objects
 Then sortTheLocations from the superclass.
 Then sendTheAnnotations back to the view controller from the superclass

 */


import Foundation
import MapKit
import CoreData
import SwiftyBeaver
import Bond


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

    var maxPoints: Int? { get set }

    var breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>? { get set }

    // MARK: Functions


    // MARK: Function signatures implemented in the Protocol Extension

    func createFetchRequestResultsControllerAndRegisterAsDelegate(with style: Style?) -> NSFetchedResultsController<NSFetchRequestResult>
    func performFetchAndReturnUnsortedBreweries(on breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery]

    // MARK: Function signatures implemented in the Concrete Class

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>)
    func concreteFetchableStrategyPerformFetchGetBreweries(from breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery]
    func createFetchRequest(with style: Style?) -> NSFetchRequest<NSFetchRequestResult>

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


    /// MapAnnotationProvider method to return the breweries currently fetched by the fetched results controller.
    internal func getBreweries() -> [Brewery] {
        return performFetchAndReturnUnsortedBreweries(on: breweryOrStyleUpdateController!)
    }


    internal func performFetchForBreweries(on breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) {
        do {
            try breweryOrStyleUpdateController.performFetch()
            //breweryLocations = concreteFetchableStrategyGetBreweries(from: breweryOrStyleUpdateController)
        } catch {
            SwiftyBeaver.error("\(#file) \(#function) Critical error unable to read database.")
        }
    }


    internal func performFetchAndReturnUnsortedBreweries(on breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery] {

        log.info("\(#file):\(#function) called")

        var breweryLocations: [Brewery] = []
        breweryLocations = concreteFetchableStrategyPerformFetchGetBreweries(from: breweryOrStyleUpdateController)
        log.info("Receive \(breweryLocations.count) from concreteFetchableStrategyPerformFetchGetBreweries")
        return breweryLocations
    }


    // MARK: MapAnnotationProvider Implementation

    internal func endSearch() -> (()->())? {
        SwiftyBeaver.info("FetchableMapStrategy endSearch called")
        return {}
    }

    // MARK: Helper Functions

    fileprivate func limitReturned(breweries: [Brewery], to maxPoints: Int) -> [Brewery] {

        var breweryLocations = breweries
        if breweryLocations.count > maxPoints {
            breweryLocations = Array(breweryLocations[0..<maxPoints])
        }
        return breweryLocations
    }
}


// MARK: -

/// Concrete class to that will constantly update whatever MapAnnotationReceiver
/// is attached to it.
final class StyleMapStrategy: NSObject, FetchableStrategy {

    // MARK: Variables

    var parentMapViewController: MapAnnotationReceiver?
    var targetLocation: CLLocation?
    var readOnlyContext: NSManagedObjectContext?
    var bounceDelay: Int = DelaysConstants.InitialDelay.rawValue
    var delayedBlockFetchSortSend: (()->())?
    var delayLoops: Int = DelaysConstants.MaximumShortDelayLoops.rawValue
    var maxPoints: Int?
    var breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>?
    var annotations: MutableObservableArray<MKAnnotation>

    // MARK: Functions
    override init() {
        annotations = MutableObservableArray<MKAnnotation>()
        super.init()
    }

    convenience init(style: Style?,
                     view: MapAnnotationReceiver,
                     location: CLLocation,
                     maxPoints points: Int,
                     inputContext: NSManagedObjectContext) {

        self.init(view: view)
        readOnlyContext = inputContext
        //runningID = Mediator.sharedInstance().nextPublicStyleStrategyID
        maxPoints = points
        targetLocation = location
        parentMapViewController = view

        SwiftyBeaver.info("StyleMapStrategy calling sortLocations in initialization")

        let breweries = initialFetchBreweries(byStyle: style)

        // FIXME can I get sortandsend together and seperate out fetch

        var breweryLocations = sortLocations(breweries)

        breweryLocations = limitReturned(breweries: breweryLocations!, to: maxPoints!)

        annotations.replace(with: convertBreweryToAnnotation(breweries: breweryLocations!))
    }


    // This is the implemented template method from Fetchable Strategy
    // it returns breweries based on a Style (StyleMapStrategy)
    func concreteFetchableStrategyPerformFetchGetBreweries(from breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery] {

        // Reaching into the Style entry and extracting the breweries that are attached to the specified style
        do {
            try breweryOrStyleUpdateController.performFetch()
        } catch let error {
            log.error("StyleMapStrategy unable to perform fetch \(error)")
        }
        log.info("Returning this many breweries \(String(describing: ((breweryOrStyleUpdateController.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery])?.count))")
        return ((breweryOrStyleUpdateController.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery]) ?? []
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

        return performFetchAndReturnUnsortedBreweries(on: controller)
    }


    // MARK: Updating function

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        log.info("StyleMapStrategy of FetchableMapStrategy controllerDidChangeContent called, next calling debounced function")

        let breweries = performFetchAndReturnUnsortedBreweries(on: controller)
        var breweryLocations = sortLocations(breweries)
        breweryLocations = limitReturned(breweries: breweryLocations!, to: maxPoints!)
        annotations.replace(with: convertBreweryToAnnotation(breweries: breweryLocations!))
    }
}


// MARK: -

final class AllBreweriesMapStrategy: NSObject, FetchableStrategy {

    // MARK: Variables
    var parentMapViewController: MapAnnotationReceiver?
    var targetLocation: CLLocation?
    var readOnlyContext: NSManagedObjectContext?
    var maxPoints: Int?
    var breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>?
    var annotations: MutableObservableArray<MKAnnotation>

    // MARK: Functions
    override init() {
        annotations = MutableObservableArray<MKAnnotation>()
        super.init()
    }

    convenience init(view: MapAnnotationReceiver,
                     location: CLLocation,
                     maxPoints points: Int,
                     inputContext: NSManagedObjectContext) {

        self.init(view: view)
        readOnlyContext = inputContext
        maxPoints = points
        targetLocation = location
        parentMapViewController = view
        SwiftyBeaver.info("AllBreweriesMapStrategy calling sortLocations in initialization.")

        var breweryLocations = sortLocations(initialFetchBreweries())!

        breweryLocations = limitReturned(breweries: breweryLocations, to: maxPoints!)

        annotations.replace(with: convertBreweryToAnnotation(breweries: breweryLocations))
    }


    // Retrieve brewery from the populated NSFetchedResultsController
    func concreteFetchableStrategyPerformFetchGetBreweries(from breweryOrStyleUpdateController: NSFetchedResultsController<NSFetchRequestResult>) -> [Brewery] {
        do {
            try breweryOrStyleUpdateController.performFetch()
        } catch let error {
            log.error("AllBreweriesMapStrategy unable to peform fetch \(error)")
        }
        log.info("Returning this many breweries \(breweryOrStyleUpdateController.fetchedObjects?.count ?? 0)")
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

        // Fetch all breweries unfiltered by style
        let controller = createFetchRequestResultsControllerAndRegisterAsDelegate(with: nil)

        return performFetchAndReturnUnsortedBreweries(on: controller)
    }


    // MARK: Updating function
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        let breweries = performFetchAndReturnUnsortedBreweries(on: controller)
        var breweryLocations = sortLocations(breweries)
        breweryLocations = limitReturned(breweries: breweryLocations!, to: maxPoints!)
        annotations.replace(with: convertBreweryToAnnotation(breweries: breweryLocations!))
        log.info("AllBreweriesMap Strategy controllerDidChangeContext Called with \(controller.fetchedObjects?.count)")
        log.info("AllBreweriesMapStrategy FetchableMapStrategy controllerDidChangeContent called, next calling debounced function")
    }
}














