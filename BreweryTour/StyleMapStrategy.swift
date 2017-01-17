//
//  StyleMapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/* 
    Subclass to map strategy provides annotation for Style chosen breweries
 
    This class will initial search for any breweries attached to the style and
    then display that style. After that it will receive notifications from it's 
    Delegate and update the annotations as a group. Since MKMapView suggests
    updating the map all at once.

 */

import Foundation
import MapKit
import CoreData

class StyleMapStrategy: MapStrategy, NSFetchedResultsControllerDelegate {

// MARK: - Constants

    let initialDelay = 1000 // 1 second
    let longDelay = 10000 // 10 seconds

    let maxShortDelayLoops = 3

    // Coredata
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


// MARK: - Variables

    var delayLoops = 0
    var bounceDelay: Int = 0 // 10 seconds

    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()

    private var debouncedFunction: (()->())? = nil


// MARK: - Functions

    init(s: Style, view: MapViewController, location: CLLocation) {
        super.init()
        targetLocation = location
        breweryLocations.removeAll()
        initialFetchBreweries(byStyle: s)
        mapViewController = view
        sortLocations()
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


    private func fetch() {
        do {
            try styleFRC.performFetch()
            breweryLocations = styleFRC.fetchedObjects?.first?.brewerywithstyle?.allObjects as! [Brewery]
        } catch {
            fatalError("Critical error unable to read database.")
        }
    }


    private func fetchSortandSend() {
        delayLoops += 1
        if delayLoops > 10 {
            bounceDelay = longDelay
            debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
                self.fetchSortandSend()
            })
        }
        fetch()
        sortLocations()
        sendAnnotationsToMap()
    }


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
            fatalError("Error reading coredata")
        }
        // Initialize debounce function and associate it with sortanddisplay
        bounceDelay = initialDelay
        debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
            self.fetchSortandSend()
        })
    }
}


// MARK: - MapViewController: UpdateManagedObjectContext

extension StyleMapStrategy: ReceiveBroadcastManagedObjectContextRefresh {
    internal func contextsRefreshAllObjects() {
        styleFRC.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try styleFRC.performFetch()
        } catch {
            fatalError("Error reading coredata")
        }
    }
}

