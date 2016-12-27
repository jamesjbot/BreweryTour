//
//  Mediator.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData

class Mediator : NSManagedObjectDisplayable {

    // MARK: Constants
    private enum types {
        case Style
        case Brewery
    }

    // Initialize the classes that need to send and receive data from the mediator
    private let styleList : StylesTableList = StylesTableList()
    private let breweryList : BreweryTableList = BreweryTableList()
    private let selectedBeersList : SelectedBeersTableList = SelectedBeersTableList()
    private let allBreweryList : AllBreweriesTableList = AllBreweriesTableList()


    // MARK: Variables

//    private var categoryViewer : CategoryViewController!
//    private var mapViewer : Observer!
//    private var beersViewer : Observer! // Should this be the Obsever or should it be the beerslist
    private var currentlySelectedManagedObjectType : types?
    // Currently I'm sharing the selection.
    // If I was to isolate it the two Views that need to know about this would be
    // the mapview and the selected beer view
    // for the SelectedBeersList I'm sending this item in set selected
    // for the mapView it's getting it itself
    private var passedItem : NSManagedObject?


    // MARK: Functions

    internal func getPassedItem() -> NSManagedObject? {
        return passedItem
    }

    internal func getStyleList() -> StylesTableList {
        return styleList
    }
    
    
    internal func getBreweryList() -> BreweryTableList {
        return breweryList
    }
    
    
    internal func getSelectedBeersList() -> SelectedBeersTableList {
        return selectedBeersList
    }


    internal func getAllBreweryList() -> AllBreweriesTableList {
        return allBreweryList
    }


    internal func allBeersAndBreweriesDeleted() {
        // TODO add more tablelists
        print("Mediator \(#line) AllBeersAndBrewsDeleted telling tableList to refresh")
        allBreweryList.mediatorRefreshFetchedResultsController()
    }

    // Singleton Implementation
    // TODO this looks like a bad way to register the mediator.
    private init(){
        // Setup to receive message from the lists
        styleList.mediator = self
        breweryList.mediator = self
        allBreweryList.mediator = self
    }
    
    internal class func sharedInstance() -> Mediator {
        struct Singleton {
            static var sharedInstance = Mediator()
        }
        return Singleton.sharedInstance
    }
    
    
//    func registerAsBeersViewer(view: Observer) {
//        beersViewer = view
//    }
//    
//    
//    func registerAsCategoryView(view: CategoryViewController) {
//        categoryViewer = view
//    }
//    
//    
//    func registerAsMapView(view : Observer){
//        mapViewer = view
//    }

    
    // When an element on categoryScreen is selected, process it on BreweryDBClient
    func selected(thisItem: NSManagedObject, completion: @escaping (_ success: Bool, _ msg : String? ) -> Void) {
        passedItem = thisItem
        print("Mediator \(#line) setting selectedBeersList prior to call: \(passedItem)")
        selectedBeersList.setSelectedItem(toNSObject: passedItem!)
        if thisItem is Brewery {
            print("Mediator\(#line) Calling mediator to downloadbeers by brewery")
            BreweryDBClient.sharedInstance().downloadBeersBy(brewery : thisItem as! Brewery,
                                                             completionHandler : completion)
        } else if thisItem is Style {
            BreweryDBClient.sharedInstance().downloadBeersAndBreweriesBy(styleID: (thisItem as! Style).id!,
                                                                         isOrganic: false,
                                                                         completion: completion)
        }
    }
}
