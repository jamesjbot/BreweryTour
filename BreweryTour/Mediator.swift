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
    private var beersViewer : Observer!
    
    internal var passingItem : NSManagedObject?
    
    private let styleList : StylesTableList = StylesTableList()
    private let breweryList : BreweryTableList = BreweryTableList()
    private let selectedBeersList : SelectedBeersTableList = SelectedBeersTableList()
    
    internal func getStyleList() -> StylesTableList {
        return styleList
    }
    
    
    internal func getBreweryList() -> BreweryTableList {
        return breweryList
    }
    
    
    internal func getSelectedBeersList() -> SelectedBeersTableList {
        return selectedBeersList
    }
    
    enum types {
        case Style
        case Brewery
    }
    
    private var currentlySelectedManagedObjectType : types?
    
    // MARK: Functions
    
    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> Mediator {
        struct Singleton {
            static var sharedInstance = Mediator()
        }
        return Singleton.sharedInstance
    }
    
    
    func registerAsBeersViewer(view: Observer) {
        beersViewer = view
    }

    
//    func tellBeersViewerToDisplayThis(styleID: String?, breweryID : String?) {
//        
//    }
    
    
    func registerAsCategoryView(view: CategoryViewController) {
        categoryViewer = view
    }
    
    
    func registerAsMapView(view : Observer){
        mapViewer = view
    }
    
    func selectedItem() -> NSManagedObject? {
        return passingItem
    }
    
    
    func selected(this: NSManagedObject) {
        passingItem = this
        if this is Style {
            currentlySelectedManagedObjectType = types.Style
            print("Style selected \(this as! Style)")
            // Tell map view to display breweries with mustdraw
            // Tell the beerslist to show all beers with the specific style id
        } else if this is Brewery {
            // Tell map view to display the nsmanagedobject w/ id
            // Tell the beerslist to show all beers with te breweryid
            
            currentlySelectedManagedObjectType = types.Brewery
            
            //selectedBeersList.selected(elementAt: <#T##IndexPath#>, completion: <#T##(Bool) -> Void#>)
            // Query api for beers at this brewery
            BreweryDBClient.sharedInstance().downloadBeersBy(brewery: this as! Brewery){
                (success) -> Void in
            }
            
            // Tell Beers view controller to load beers with the brewery id
            // I don't need to tell Beers view controller to do this as the NSFetchedResultsController that backs
            // it now will automatically update the view.
            
            print("Brewery selected \(this as! Brewery)")
        }
    }
    
}
