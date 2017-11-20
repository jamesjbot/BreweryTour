//
//  Mediator.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData
import MapKit
import CoreLocation
import SwiftyBeaver

/*
 This class manages message passing across the app
 If a selection is made on the selection screen then we can 
 notify the other view to update because of that change.
 If the database data is deleted we can notify the views to update their content.
 */

class Mediator {

    // MARK: Constants

    // MARK: Variables
    internal var breweryDBClient: BreweryDBClientProtocol?
    private var automaticallySegueValue: Bool = true
    fileprivate var busyObservers: [BusyObserver] = []
    fileprivate var contextObservers: [ReceiveBroadcastManagedObjectContextRefresh] = [ReceiveBroadcastManagedObjectContextRefresh]()

    fileprivate var floatingAnnotation: MKAnnotation?
    fileprivate var lastMapSliderValue: Int = 42

    fileprivate var passedItemObservers: [ReceiveBroadcastSetSelected] = []
    fileprivate var passedItem: NSManagedObject?

    // StyleMapStrategy variables
    internal var onlyValidStyleStrategy: Int = 1
    internal var nextPublicStyleStrategyID: Int {
        get {
            StyleStrategyID = StyleStrategyID + 1
            onlyValidStyleStrategy = StyleStrategyID
            return StyleStrategyID
        }
    }
    private var StyleStrategyID:Int = 1

    // MARK: Functions

    // MARK: - PassingItem
    internal func getPassedItem() -> NSManagedObject? {
        return passedItem
    }


    // MARK: - Segueing
    internal func isAutomaticallySegueing() -> Bool {
        return automaticallySegueValue
    }

    internal func setAutomaticallySegue(to: Bool) {
        automaticallySegueValue = to
    }


    // MARK: - Mapslider values
    internal func lastSliderValue() -> Int {
        return lastMapSliderValue
    }

    internal func setLastSliderValue(_ i: Int) {
        lastMapSliderValue = Int(i)
    }


    // MARK: - Singleton Implementation
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

    private func notifyPassedItemObservers(thisItem: NSManagedObject) {
        for observer in passedItemObservers {
            observer.updateObserversSelected(item: thisItem)
        }
    }

    internal func registerForObjectUpdate(observer: ReceiveBroadcastSetSelected) {
        passedItemObservers.append(observer)
    }


    // When an element on categoryScreen is selected, process it on BreweryDBClient
    internal func select(thisItem: NSManagedObject?, state: String? ,completion: @escaping (_ success: Bool, _ msg : String? ) -> Void) {

        // These items can sometimes be nil.
        if let thisItem = thisItem {
            passedItem = thisItem
        } else {
            passedItem = nil
        }

        if let state = state {
            BreweryDBClient.sharedInstance().downloadBreweries(byState: state)
            { (success, msg) -> Void in
            }
            return
        }

        notifyPassedItemObservers(thisItem: passedItem!)

        if thisItem is Brewery {
            BreweryDBClient.sharedInstance().downloadBeersBy(brewery : thisItem as! Brewery,
                                                             completionHandler : completion)
        } else if thisItem is Style {
            BreweryDBClient.sharedInstance().downloadBeersAndBreweriesBy(
                styleID: (thisItem as! Style).id!,
                completion: completion)
        }
    }
}


// MARK: - MediatorBusyObserver

extension Mediator: MediatorBusyObserver {

    // Busy ness depends on if the client is using the network connection
    func isSystemBusy() -> Bool {

        return breweryDBClient?.isDownloading ?? false
    }


    func notifyStartingWork() {
        for observer in busyObservers {
            observer.startAnimating()
        }
    }


    func notifyStoppingWork() {
        for observer in busyObservers {
            observer.stopAnimating()
        }
    }


    func registerForBusyIndicator(observer: BusyObserver) {
        busyObservers.append(observer)
    }
}


// MARK: - BroadcastManagedObjectContextRefresh

extension Mediator: BroadcastManagedObjectContextRefresh {

    internal func allBeersAndBreweriesDeleted() {
        SwiftyBeaver.info("Mediator allBeersAndBreweriesDelete called")

        resetSelectedItemToNil()

        // Notify observers of changes.
        for observer in contextObservers {
            observer.contextsRefreshAllObjects()
            SwiftyBeaver.info("Mediator contextsRefreshed; notified \(observer) ")
        }
    }


    internal func registerManagedObjectContextRefresh(_ a: ReceiveBroadcastManagedObjectContextRefresh) {
        // Add a new observer
        contextObservers.append(a)
    }
}


// MARK: - StorableFloatingAnnotation

extension Mediator: StorableFloatingAnnotation {

    internal func getFloatingAnnotation() -> MKAnnotation? {
        return floatingAnnotation
    }


    internal func setFloating(annotation: MKAnnotation) {
        floatingAnnotation = annotation
    }
}


// MARK: - Fileprivate helper functions

extension Mediator {
    fileprivate func resetSelectedItemToNil() {
        passedItem = nil
    }
}


