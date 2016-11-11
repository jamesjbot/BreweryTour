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
        } catch {
            fatalError()
        }
        
        guard frc.fetchedObjects?.count == 0 else {
            // We have brewery entries go ahead and display them viewcontroller
            return
        }
        
        // Fetch all the breweries in the database.
        BreweryDBClient.sharedInstance().downloadAllBreweries() {
            (success, msg) -> Void in
            if msg == "All Pages Processed" {
                print(msg)
                do {
                    try self.frc.performFetch()
                } catch {
                    fatalError()
                }
            }

        }
    }
    
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("BreweryTableList willchange")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        //print("BreweryTableList changed object")
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("BreweryTableList didChange")
        observer.sendNotify(s: "reload data")
        //Datata = frc.fetchedObjects!
    }
    
    
    func temporaryFetchData(){
        do {
            try frc.performFetch()
            print("Retrieved this many styles \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results. 
        //Fetch data because when we use the on screen segemented display to switch to this it will not display, because of the back delete.
        temporaryFetchData()
        guard searchText == "" else {
            print("\(#function) filtered object count \(filteredObjects.count)")
            return filteredObjects.count
        }
        print("\(#function) fetched objects count \(frc.fetchedObjects?.count)")
        return frc.fetchedObjects!.count
    }
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        // Debugging code because breweries with a nil name are leaking thru
        // assert((frc.fetchedObjects?.count)! > 0)
        print("\(#function) fetchedobject count \(frc.fetchedObjects?.count)")
        for i in frc.fetchedObjects! {
            print("Brewery name: \(i.name) \(i.id)")
            assert(i.name != nil)
        }
        
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))!
        //print("we updated the filtered contents to \(filteredObjects.count)")
        return filteredObjects
    }
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        DispatchQueue.main.async {
            if searchText != "" {
                cell.textLabel?.text = (self.filteredObjects[indexPath.row]).name
            } else {
                cell.textLabel?.text = (self.frc.fetchedObjects![indexPath.row]).name
            }
        }
        return cell
    }
    
    
    func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success : Bool, _ msg : String?) -> Void ) -> AnyObject? {
        // We are only selecting one brewery to display, so we need to remove
        // all the breweries that are currently displayed. And then turn on the selected brewery
        var savedBreweryForDisplay : Brewery!
        if searchText == "" {
            savedBreweryForDisplay = (frc.object(at:elementAt)) as Brewery
        } else {
            savedBreweryForDisplay = (filteredObjects[elementAt.row]) as Brewery
        }
        // Tell mediator about the brewery I want to display
        // Then mediator will tell selectedBeerList what to display
        mediator.selected(thisItem: savedBreweryForDisplay)
        
        // TODO need to get all the beers for this brewery
        completion(true, "Success")
        //print("Tell mediator this brewery was selected")
        return nil
    }
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> (Void))?) {
        print("searchForuserEntered beer called")
        BreweryDBClient.sharedInstance().downloadBreweryBy(name: searchTerm) {
            (success, msg) -> Void in
            print("BreweryTableList Returned from BreweryDBClient")
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                try self.frc.performFetch()
                print("BreweryTableList Saved this many breweries in model \(self.frc.fetchedObjects?.count)")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
            }
        }
    }
    
}
