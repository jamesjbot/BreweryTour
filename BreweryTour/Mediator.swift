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
    
    internal func getMapData() -> NSManagedObject? {
        return passingItem
    }
    enum types {
        case Style
        case Brewery
    }
    
    private var currentlySelectedManagedObjectType : types?
    
    // MARK: Functions
    
    // MARK: Singleton Implementation
    
    private init(){
        // Setup to receive message from the lists
        styleList.mediator = self
        breweryList.mediator = self
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
    
//    func getSelectedItem() -> NSManagedObject? {
//        return passingItem
//    }
    
    
    func selected(thisItem: NSManagedObject, organic : Bool) {
        passingItem = thisItem
        print("Mediator setting selectedBeersList prior to call: \(passingItem)")
        selectedBeersList.setSelectedItem(toNSObjectID: passingItem!.objectID, organic: organic)
    }
    
}
