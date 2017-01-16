//
//  Mediator.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData

/*
 This class managed states changes across the app
 If a selection is made on the selection screen then we can 
 notify the other Views That will need to update because of that change.
 */

protocol BusyObserver {
    func stopAnimating()
    func registerAsBusyObserverWithMediator()
}

protocol MediatorBusyObserver {
    func registerForBusyIndicator(observer: BusyObserver)
    //func notifyStartingWork()
    func notifyStoppingWork()
    func isSystemBusy() -> Bool
}


extension Mediator: MediatorBusyObserver {

    func registerForBusyIndicator(observer: BusyObserver) {
        busyObservers.append(observer)
    }


    func notifyStoppingWork() {
        for i in busyObservers {
            i.stopAnimating()
        }
    }


    func isSystemBusy() -> Bool {
        return BreweryAndBeerCreationQueue.sharedInstance().isBreweryAndBeerCreationRunning()
    }
}

protocol MapUpdateable {
    func updateMap()
}

protocol ObserverMapChanges {
    func registerMapObservers(m: MapUpdateable)
    func broadcastMapChanges()

}


extension Mediator: ObserverMapChanges {
    func registerMapObservers(m: MapUpdateable) {
        mapObservers.append(m)
    }

    func broadcastMapChanges() {
        for i in mapObservers {
            i.updateMap()
        }
    }
}

class Mediator {

    // MARK: Constants

    // MARK: Variables
    fileprivate var objectObserver: [ReceiveBroadcastSetSelected] = []

    fileprivate var mapObservers: [MapUpdateable] = []

    fileprivate var contextObservers: [ReceiveBroadcastManagedObjectContextRefresh] = [ReceiveBroadcastManagedObjectContextRefresh]()

    fileprivate var busyObservers: [BusyObserver] = []

    private var automaticallySegueValue: Bool = false

    fileprivate var passedItem : NSManagedObject?

    fileprivate var observersOfBreweryImages: [BreweryAndBeerImageNotifiable] = [BreweryAndBeerImageNotifiable]()

    // MARK: Functions

    internal func setAutomaticallySegue(to: Bool) {
        automaticallySegueValue = to
    }

    internal func isAutomaticallySegueing() -> Bool {
        return automaticallySegueValue
    }

    internal func getPassedItem() -> NSManagedObject? {
        return passedItem
    }
    
    // Singleton Implementation
    private init(){
    }
    
    internal class func sharedInstance() -> Mediator {
        struct Singleton {
            static var sharedInstance = Mediator()
        }
        return Singleton.sharedInstance
    }
}


extension Mediator: MediatorBroadcastSetSelected {


    // When an element on categoryScreen is selected, process it on BreweryDBClient
    internal func select(thisItem: NSManagedObject, completion: @escaping (_ success: Bool, _ msg : String? ) -> Void) {
        passedItem = thisItem
        //Notify everyone who wants to know what the selcted item is
        for i in objectObserver {
            i.updateObserversSelected(item: thisItem)
        }

        if thisItem is Brewery {
            //print("Mediator\(#line) Calling mediator to downloadbeers by brewery")
            BreweryDBClient.sharedInstance().downloadBeersBy(brewery : thisItem as! Brewery,
                                                             completionHandler : completion)
        } else if thisItem is Style {
            BreweryDBClient.sharedInstance().downloadBeersAndBreweriesBy(
                styleID: (thisItem as! Style).id!,
                completion: completion)
        }
    }

    internal func registerForObjectUpdate(observer: ReceiveBroadcastSetSelected) {
        objectObserver.append(observer)
    }

}

extension Mediator: BroadcastManagedObjectContextRefresh {

    internal func registerManagedObjectContextRefresh(_ a: ReceiveBroadcastManagedObjectContextRefresh) {
        // Add a new observer
        contextObservers.append(a)
    }

    internal func allBeersAndBreweriesDeleted() {

        for i in contextObservers {
            print("Mediator says there are \(contextObservers.count) contextObservers to update")
            i.contextsRefreshAllObjects()
        }

    }

}

extension Mediator: BreweryAndBeerImageNotifier {

    func broadcastToBreweryImageObservers() {
        guard (observersOfBreweryImages.count) > 0 else {
            return
        }
        for i in observersOfBreweryImages {
            i.tellImagesUpdate()
        }
    }

    func registerAsBrewryImageObserver(t: BreweryAndBeerImageNotifiable) {
        observersOfBreweryImages.append(t)
    }

}


