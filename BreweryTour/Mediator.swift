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
    
    
    func selected(thisItem: NSManagedObject) {
        passingItem = thisItem
        print("prior to call: \(passingItem)")
        selectedBeersList.setSelectedItem(toNSObjectID: passingItem!.objectID)
        selectedBeersList.mediatorPerformFetch()
//        if thisItem is Style {
//            currentlySelectedManagedObjectType = types.Style
//            print("Style selected \(thisItem as! Style)")
//            // Tell map view to display breweries with mustdraw
//            //print("sending message to map")
//            //mapViewer.sendNotify(s: "Display MustDraw")
//            // Tell the beerslist to show all beers with the specific style id
//            print("sending message to beers controller")
//            //beersViewer.sendNotify(s: "Show beers with this style")
//        } else if thisItem is Brewery {
//            // Tell map view to display the nsmanagedobject w/ id
//            //print("sending message to map viewer")
//            //mapViewer.sendNotify(s: "Draw this brewery")
//            // Tell the beerslist to show all beers with te breweryid
//            print("sending message to beers controller")
            //beersViewer.sendNotify(s: "Show beers by this brewery")
            
        //currentlySelectedManagedObjectType = types.Brewery
            
            //selectedBeersList.selected(elementAt: //, completion: <#T##(Bool) -> Void#>)
            // Query api for beers at this brewery
//            BreweryDBClient.sharedInstance().downloadBeersBy(brewery: this as! Brewery){
//                (success) -> Void in
//            }
            
            // Tell Beers view controller to load beers with the brewery id
            // I don't need to tell Beers view controller to do this as the NSFetchedResultsController that backs
            // it now will automatically update the view.
            
            //print("Brewery selected \(this as! Brewery)")
    //}
    }
    
}
