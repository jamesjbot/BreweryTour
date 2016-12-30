//
//  BreweryTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/* 
 This is the view model backing the breweries with specified styles table on the
 main category viewcontroller.
 It initially shows nothing, waiting for a style to be select.
 */


import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, Subject {

    // MARK: Constants

    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: Variables

    var observer : Observer!

    // variables for selecting breweries with a style
    var displayableBreweries = [Brewery]()
    var newBeers = [Beer]()

    internal var mediator: NSManagedObjectDisplayable!

    // variable for search filtering
    internal var filteredObjects: [Brewery] = [Brewery]()
    
    // Currently watches the main context (readOnlyContext)
    internal var coreDataBeerFRCObserver: NSFetchedResultsController<Beer>!
    

    // MARK: - Functions

    //
    /*
     On start up we don't have a style selected so this ViewController will be
     blank
     */
    override init(){
        super.init()
    }
    
    
    /* 
     Fetch breweries based on style selected.
     The CategoryViewController will fire this method
     to get the brewery entries from the database
     */
    internal func displayBreweriesWith(style : Style, completion: (_ success: Bool) -> Void){
        /* 
         First look for all the beers with a style
         Then set all the breweries related to those beers
         into displayableBreweries
         */
        print("BreweryTableLISt \(#line) Requesting style: \(style.id!) ")
        let request : NSFetchRequest<Beer> = Beer.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "styleID = %@", style.id!)
        var results : [Beer]!
        coreDataBeerFRCObserver = NSFetchedResultsController(fetchRequest: request ,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        print("BreweryTableList \(#line) beerfrc delegate assigned ")
        coreDataBeerFRCObserver.delegate = self
        /*
         TODO When you select styles and favorite a brewery, go to favorites breweries and pick a style
         This frc will totally overwrite because it will detect changes in the breweries from favoriting
         forcing a reload on the mapviewcontroller.
         */
        // This must block because the mapView must be populated before it displays.
        //        container?.performBackgroundTask({
        //            (context) -> Void in

        // remove the breweries we have for display
        self.displayableBreweries.removeAll()

        readOnlyContext?.perform() {
            do {
                try self.coreDataBeerFRCObserver?.performFetch()
                results = (self.coreDataBeerFRCObserver.fetchedObjects)! as [Beer]
            } catch {
            }
            for beer in results {
                guard beer.brewer != nil else {
                    fatalError()
                }
                if !self.displayableBreweries.contains(beer.brewer!) {
                    self.displayableBreweries.append(beer.brewer!)
                }
            }
            self.observer.sendNotify(from: self, withMsg: "reload data")
        }
    }


    // Allow CategoryViewController to register for updates.
    func registerObserver(view: Observer) {
        observer = view
    }
    
}


extension BreweryTableList: TableList {

    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        DispatchQueue.main.async {
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            guard let searchText = searchText else {
                return
            }
            guard searchText.isEmpty ? indexPath.row < self.displayableBreweries.count :
                indexPath.row < self.filteredObjects.count else {
                return
            }
            if searchText.isEmpty {
                cell.textLabel?.text = (self.displayableBreweries[indexPath.row]).name
            } else {
                cell.textLabel?.text = (self.filteredObjects[indexPath.row]).name
            }
            cell.setNeedsDisplay()
        }
        return cell
    }
    
    
    func filterContentForSearchText(searchText: String){// -> [NSManagedObject] {
        // BreweryTableList Observes the persistent Context and I only saved them
        // the main context and so there are none.
        // Debugging code because breweries with a nil name are leaking thru
        // assert((frc.fetchedObjects?.count)! > 0)
        // Only filter object if there are objects to filter.
        guard displayableBreweries.count > 0 else {
            //return []
            filteredObjects.removeAll()
            return
        }
        filteredObjects = (displayableBreweries.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results.
        // Fetch data because when we use the on screen segemented display to switch to this it will refresh the display, because of the back delete.
        //er crektemporaryFetchData()
        // First thing called on a reload from category screen
        guard searchText == "" else {
            print("BreweryTableList \(#line) \(#function) filtered object count \(filteredObjects.count)")
            return filteredObjects.count
        }
        return displayableBreweries.count
    }
    
    
    internal func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success : Bool, _ msg : String?) -> Void ) -> AnyObject? {
        // We are only selecting one brewery to display, so we need to remove
        // all the breweries that are currently displayed. And then turn on the selected brewery
        var savedBreweryForDisplay : Brewery!
        if searchText == "" {
            savedBreweryForDisplay = (displayableBreweries[elementAt.row]) as Brewery
        } else {
            savedBreweryForDisplay = (filteredObjects[elementAt.row]) as Brewery
        }
        // Tell mediator about the brewery I want to display
        // Then mediator will tell selectedBeerList what to display
        mediator.selected(thisItem: savedBreweryForDisplay, completion: completion)
        return nil
    }
    
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> (Void))?) {
        print("BreweryTableList \(#line)searchForuserEntered beer called")
        completion!(false,"This screen only show breweries with the selected style, try brewery search on the All Breweries button.")
    }

}

extension BreweryTableList : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("BreweryTableList \(#line) BreweryTableList willchange")
        newBeers = [Beer]()
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("BreweryTableList \(#line) BreweryTableList changed object")
        switch (type){
        case .insert:
            newBeers.append(anObject as! Beer)
            break
        case .delete:
            break
        case .move:
            break
        case .update:
            break
        }
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Process new beers
        for beer in newBeers {
            if !self.displayableBreweries.contains(beer.brewer!) {
                self.displayableBreweries.append(beer.brewer!)
            }
        }
        print("BreweryTableList \(#line) BreweryTableList controllerdidChangeContent notify observer")
        // TODO We're preloading breweries do I still need this notify
        print("BrweryTableList \(#line) Notify viewcontroller on controllerDidChangeContent delegate.")
        observer.sendNotify(from: self, withMsg: "reload data")
        print("BreweryTableList \(#line) There are now this many breweries \(controller.fetchedObjects?.count)")
        //Datata = frc.fetchedObjects!
    }
}

