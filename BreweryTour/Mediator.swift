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

class Mediator : NSManagedObjectDisplayable {

    // MARK: Constants

    // Initialize the classes that need to send and receive data from the mediator
    private let styleList : StylesTableList = StylesTableList()
    private let breweryWithStyleList : BreweryTableList = BreweryTableList()
    private let selectedBeersList : SelectedBeersTableList = SelectedBeersTableList()
    private let allBreweryList : AllBreweriesTableList = AllBreweriesTableList()

    // MARK: Variables

    private var automaticallySegueValue: Bool = false

    private var passedItem : NSManagedObject?


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

    internal func getStyleList() -> StylesTableList {
        return styleList
    }
    
    
    internal func getBreweryList() -> BreweryTableList {
        return breweryWithStyleList
    }
    
    
    internal func getSelectedBeersList() -> SelectedBeersTableList {
        return selectedBeersList
    }


    internal func getAllBreweryList() -> AllBreweriesTableList {
        return allBreweryList
    }


    internal func allBeersAndBreweriesDeleted() {
        // TODO add more tablelists
        //print("Mediator \(#line) AllBeersAndBrewsDeleted telling tableList to refresh")
        allBreweryList.mediatorRefreshFetchedResultsController()
    }

    
    // Singleton Implementation
    private init(){
        // Setup to receive message from the lists
        styleList.mediator = self
        breweryWithStyleList.mediator = self
        allBreweryList.mediator = self
    }
    
    internal class func sharedInstance() -> Mediator {
        struct Singleton {
            static var sharedInstance = Mediator()
        }
        return Singleton.sharedInstance
    }

    
    // When an element on categoryScreen is selected, process it on BreweryDBClient
    func selected(thisItem: NSManagedObject, completion: @escaping (_ success: Bool, _ msg : String? ) -> Void) {
        passedItem = thisItem
        //print("Mediator \(#line) setting selectedBeersList prior to call: \(passedItem)")
        selectedBeersList.setSelectedItem(toNSObject: passedItem!)
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
}
