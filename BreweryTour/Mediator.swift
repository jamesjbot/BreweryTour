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
    
    private var categoryViewer : CategoryViewController!
    private var mapViewer : Observer!
    private var beersViewer : Observer! // Should this be the Obsever or should it be the beerslist
    
    internal var passingItem : NSManagedObject?
    internal var organic : Bool?
    private let styleList : StylesTableList = StylesTableList()
    private let breweryList : BreweryTableList = BreweryTableList()
    private let selectedBeersList : SelectedBeersTableList = SelectedBeersTableList()
    private let allBreweryList : AllBreweriesTableList = AllBreweriesTableList()
    //private let mapModel : MapViewModel = MapViewModel()
    
    
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
    
    internal func getMapData() -> NSManagedObject? {
        return passingItem
    }
    
    enum types {
        case Style
        case Brewery
    }
    
    private var currentlySelectedManagedObjectType : types?
    
    // MARK: Functions

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
    
    
    func registerAsBeersViewer(view: Observer) {
        beersViewer = view
    }
    
    
    func registerAsCategoryView(view: CategoryViewController) {
        categoryViewer = view
    }
    
    
    func registerAsMapView(view : Observer){
        mapViewer = view
    }
    
    
    // When an element on categoryScreen is selected, process it on BreweryDBClient
    func selected(thisItem: NSManagedObject, completion: @escaping (_ success: Bool, _ msg : String? ) -> Void) {
        passingItem = thisItem
        print("Mediator \(#line) setting selectedBeersList prior to call: \(passingItem)")
        selectedBeersList.setSelectedItem(toNSObject: passingItem!)
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
