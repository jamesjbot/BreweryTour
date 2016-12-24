//
//  BreweryTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/* 
 This is the view model backing the brewery table on the main category view
 controller
 */


import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, Subject {

    var observer : Observer!

    func registerObserver(view: Observer) {
        observer = view
    }
    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Brewery] = [Brewery]()
    
    // Currently watches the persistentContext
    internal var frc : NSFetchedResultsController<Brewery>!
    
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext
    
    override init(){
        super.init()
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.fetchLimit = 10000
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            observer.sendNotify(from: self, withMsg: "Error fetching data")
        }
        
        guard frc.fetchedObjects?.count == 0 else {
            // We have brewery entries go ahead and display them viewcontroller
            // TODO remove this temporary code to detect if there are breweries here already
            //fatalError()
            return
        }
        
        // Since we didn't exit trying to find  the breweries above
        // Fetch all the breweries from the internet.
//        BreweryDBClient.sharedInstance().downloadAllBreweries() {
//            (success, msg) -> Void in
//            if msg == "All Pages Processed" {
//                print("BreweryTableList \(#line) init() msg:\(msg) dbbrewery client sent back completion handlers saying success:\(success))")
//                print("BreweryTableList \(#line) Sending CategoryView a notification to reload breweryTablelist ")
//                self.observer.sendNotify(from: self, withMsg: "reload data")
////                do {
////                    print("BreweryTableList \(#line)BreweryTableList \(#line)Is this fetch needed?")
////                    try self.frc.performFetch()
////                } catch {
////                    fatalError()
////                }
//            }
//
//        }
    }
    
    
    

    
    
    func temporaryFetchData(){
        do {
            try frc.performFetch()
            print("BreweryTableList \(#line) Temporary data fetch Retrieved this many Breweries \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
        do {
            try frc.performFetch()
            print("BreweryTableList \(#line) Temporary data fetch Retrieved this many Breweries \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
        do {
            try frc.performFetch()
            print("BreweryTableList \(#line) Temporary data fetch Retrieved this many Breweries \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
        do {
            try frc.performFetch()
            print("BreweryTableList \(#line) Temporary data fetch Retrieved this many Breweries \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results. 
        // Fetch data because when we use the on screen segemented display to switch to this it will refresh the display, because of the back delete.
        //er crektemporaryFetchData()
        guard searchText == "" else {
            print("BreweryTableList \(#line) \(#function) filtered object count \(filteredObjects.count)")
            return filteredObjects.count
        }
        print("BreweryTableList \(#line) \(#function) fetched objects count \(frc.fetchedObjects?.count)\nfrc:\(frc.fetchedObjects?.first)")
        return frc.fetchedObjects!.count
    }
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        // BreweryTableList Observes the persistent Context and I only saved them
        // the main context and so there are none.
        // Debugging code because breweries with a nil name are leaking thru
        // assert((frc.fetchedObjects?.count)! > 0)
        // Only filter object if there are objects to filter.
        guard frc.fetchedObjects != nil else {
            return []
        }
        guard (frc.fetchedObjects?.count)! > 0 else {
            return []
        }
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))!
        return filteredObjects
    }
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        DispatchQueue.main.async {
            print("BreweryTableList \(#line) On the UITableViewCell u sent me I'm putting text on it. ")
            if searchText != "" {
                cell.textLabel?.text = (self.filteredObjects[indexPath.row]).name
            } else {
                cell.textLabel?.text = (self.frc.fetchedObjects![indexPath.row]).name
            }
            cell.setNeedsDisplay()
        }
        return cell
    }
}

extension BreweryTableList: TableList {

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
        mediator.selected(thisItem: savedBreweryForDisplay, completion: completion)
        return nil
    }
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> (Void))?) {
        print("BreweryTableList \(#line)searchForuserEntered beer called")
        BreweryDBClient.sharedInstance().downloadBreweryBy(name: searchTerm) {
            (success, msg) -> Void in
            print("BreweryTableList \(#line)BreweryTableList Returned from BreweryDBClient")
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                try self.frc.performFetch()
                print("BreweryTableList \(#line)BreweryTableList Saved this many breweries in model \(self.frc.fetchedObjects?.count)")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
            }
        }
    }
    
}

extension BreweryTableList : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("BreweryTableList \(#line) BreweryTableList willchange")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("BreweryTableList \(#line) BreweryTableList changed object")
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("BreweryTableList \(#line) BreweryTableList controllerdidChangeContent notify observer")
        // TODO We're preloading breweries do I still need this notify
        observer.sendNotify(from: self, withMsg: "reload data")
        print("BreweryTableList \(#line) There are now this many breweries \(controller.fetchedObjects?.count)")
        print("BreweryTableList \(#line) Rejected breweries \(BreweryDBClient.sharedInstance().rejectedBreweries)")
        //Datata = frc.fetchedObjects!
    }
}

