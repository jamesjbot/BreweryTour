//
//  BreweryTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the view model backing the brewery table on the main category view
    controller
 **/


import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, TableList, NSFetchedResultsControllerDelegate, Subject {

    var observer : Observer!

    func registerObserver(view: Observer) {
        observer = view
    }
    


    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Brewery] = [Brewery]()
    internal var frc : NSFetchedResultsController<Brewery>!
    
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext
    
    let backgroundContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.backgroundContext
    
    override init(){
        super.init()
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
//        if onlyOrganic {
//            request.predicate = NSPredicate(format: "hasOrganic == true")
//        }
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: persistentContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
            //print("Retrieved this many styles \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
        
        guard frc.fetchedObjects?.count == 0 else {
            // We have entries go ahead and display them viewcontroller
            //completion(true)
            print("\(#file)\n\(#line)We have Brewery Entries don't fetch from the databse")
            return
        }
        
        // Here is where i force  the BreweryTableList to go find another brewery
        fatalError()
        print("Attempting to get brooklyn brewery")
        BreweryDBClient.sharedInstance().downloadBreweryBy(name: "brooklyn") {
            (success) -> Void in
            print("Returned from getting brewery")
            do {
                try self.frc.performFetch()
                print("Saved this many breweries in model \(self.frc.fetchedObjects?.count)")
                //completion(true)
            } catch {
                //completion(false)
                fatalError("Fetch failed critcally")
            }
            return
        }
//        if frc.fetchedObjects?.count == 0 {
//            print("No brewery results going to get them from the database")
//            // TODO Remove organic we will query the database for it
//            BreweryDBClient.sharedInstance().downloadAllBreweries(isOrganic: false){
//                (success) -> Void in
//                if success {
//                    print("Database succeeded populating")
//                    do {
//                        try self.frc.performFetch()
//                        //self.listOfBreweries = frc.fetchedObjects! as [Brewery]
//                        print("Saved this many breweries in model \(self.frc.fetchedObjects?.count)")
//                        //completion(true)
//                    } catch {
//                        //completion(false)
//                        fatalError("Fetch failed critcally")
//                    }
//                }
//            }
//        }
    }
    
    internal func getListOfBreweries(onlyOrganic : Bool,
                                     completion: @escaping(_ compelte: Bool ) -> Void) {
        // Get all the breweries from coredata
        

        

        // First we see if we already have the styles saved to coredata;
        // if so use the coredata saved styles
        // If we don't have the styles save go query BreweryDB for them.
        //        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        //        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        //        fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: (coreDataStack?.backgroundContext)!, sectionNameKeyPath: nil, cacheName: nil)
        //        fetchedResultsController.delegate = self
        //        do {
        //            try fetchedResultsController.performFetch()
        //            print("Fetch breweries complete \(fetchedResultsController.fetchedObjects?.count)")
        //
        //        } catch {
        //            fatalError("Fetch failed critcally")
        //        }
        
        // This was already dont
        // If fetch did not return any items query the REST Api
        //        if fetchedResultsController.fetchedObjects?.count == 0 {
        //            breweryDB.downloadBeerStyles() {
        //                (success) -> Void in
        //                if success {
        //                    // TODO this might not be needed anymore
        //                    //self.styleTable.reloadData()
        //                    // Now that the delegate is properly hooked up
        //                }
        //            }
        //        }
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("BreweryTableList willchange")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("Brewery changed object")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Brewery TableList didChange")
        observer.sendNotify(s: "reload data")
        //Datata = frc.fetchedObjects!
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        //print("getNumberofrows on \(searchText)")
        guard searchText == "" else {
            return filteredObjects.count
        }
        return frc.fetchedObjects!.count
    }
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))!
        //print("we updated the filtered contents to \(filteredObjects.count)")
        return filteredObjects
    }
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        if searchText != "" {
            //print("size:\(filteredObjects.count) want:\(indexPath.row) ")
            cell.textLabel?.text = (filteredObjects[indexPath.row]).name
        } else {
            cell.textLabel?.text = (frc.fetchedObjects![indexPath.row]).name
        }
        return cell
    }
    
    
    func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success : Bool, _ msg : String?) -> Void ) {
        // We are only selecting one brewery to display, so we need to remove
        // all the breweries that are currently displayed. And then turn on the selected brewery
        var savedBreweryForDisplay : Brewery!
        if searchText == "" {
            savedBreweryForDisplay = (frc.fetchedObjects?[elementAt.row])! as Brewery
        } else {
            savedBreweryForDisplay = (filteredObjects[elementAt.row]) as Brewery
        }
        // Tell mediator about the brewery I want to display
        mediator.selected(thisItem: savedBreweryForDisplay)
        
        
        // Turn off mustDraw on all breweries that are marked to turn on.
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "mustDraw == true")
        var stopDrawingTheseBreweries : [Brewery]!
        do {
            try stopDrawingTheseBreweries = (coreDataStack?.backgroundContext.fetch(request))! as [Brewery]
        } catch {
            fatalError("Failure to query breweries")
        }
        print("Completed getting Breweries")
        // Mark the brewery as must display, the map controller will pull these elements out of the model itself
        for i in stopDrawingTheseBreweries {
            i.mustDraw = false
        }
        savedBreweryForDisplay.mustDraw = true
        do {
            try coreDataStack?.backgroundContext.save()
        } catch {
            fatalError()
        }
        // TODO need to get all the beers for this brewery
        completion(true, "Success")
        //print("Tell mediator this brewery was selected")
    }
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> (Void))?) {
        print("searchForuserEntered beer called")
        BreweryDBClient.sharedInstance().downloadBreweryBy(name: searchTerm) {
            (success, msg) -> Void in
            print("Returned from getting brewery")
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                try self.frc.performFetch()
                print("Saved this many breweries in model \(self.frc.fetchedObjects?.count)")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
                fatalError("Fetch failed critcally")
            }
        }
    }
    
}
