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


class Mediator {

    // MARK: Variables
    
    fileprivate var objectObserver: [ReceiveBroadcastSetSelected] = []

    fileprivate var contextObservers: [ReceiveBroadcastManagedObjectContextRefresh] = [ReceiveBroadcastManagedObjectContextRefresh]()

    fileprivate var busyObservers: [BusyObserver] = []

    private var automaticallySegueValue: Bool = false

    fileprivate var passedItem: NSManagedObject?

    fileprivate var lastMapSliderValue: Int = 250
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

    internal func setLastSliderValue(_ i: Int) {
        lastMapSliderValue = Int(i)
    }

    internal func lastSliderValue() -> Int {
        return lastMapSliderValue
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


// MARK: - MediatorBroadcastSetSelected

extension Mediator: MediatorBroadcastSetSelected {

    // When an element on categoryScreen is selected, process it on BreweryDBClient
    internal func select(thisItem: NSManagedObject, completion: @escaping (_ success: Bool, _ msg : String? ) -> Void) {
        passedItem = thisItem
        //Notify everyone who wants to know what the selcted item is
        for i in objectObserver {
            i.updateObserversSelected(item: thisItem)
        }

        if thisItem is Brewery {
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


// MARK: - MediatorBusyObserver

extension Mediator: MediatorBusyObserver {

    func registerForBusyIndicator(observer: BusyObserver) {
        busyObservers.append(observer)
    }

    func notifyStoppingWork() {
        for i in busyObservers {
            i.stopAnimating()
        }
    }

    func notifyStartingWork() {
        for i in busyObservers {
            i.startAnimating()
        }
    }

    func isSystemBusy() -> Bool {
        return BreweryAndBeerCreationQueue.sharedInstance().isBreweryAndBeerCreationRunning()
    }
}


// MARK: - BroadcastManagedObjectContextRefresh

extension Mediator: BroadcastManagedObjectContextRefresh {

    internal func registerManagedObjectContextRefresh(_ a: ReceiveBroadcastManagedObjectContextRefresh) {
        // Add a new observer
        contextObservers.append(a)
    }

    internal func allBeersAndBreweriesDeleted() {
        passedItem = nil
        for i in contextObservers {
            i.contextsRefreshAllObjects()
        }
    }
}


