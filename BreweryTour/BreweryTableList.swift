//
//  BreweryTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/* 
 This is the view model backing the breweries with specified styles table on the main category view
 controller
 */


import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, Subject {

    // MARK: Variables
    var observer : Observer!

    var displayableBreweries = [Brewery]()
    var newBeers = [Beer]()
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Brewery] = [Brewery]()
    
    // Currently watches the persistentContext
    //internal var frc : NSFetchedResultsController<Brewery>!
    internal var beerFRC: NSFetchedResultsController<Beer>!
    
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext
    
    // MARK: - Functions
    
    override init(){
        super.init()
//        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
//        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
//        request.fetchLimit = 10000
//        frc = NSFetchedResultsController(fetchRequest: request,
//                                         managedObjectContext: readOnlyContext!,
//                                         sectionNameKeyPath: nil,
//                                         cacheName: nil)
//        frc.delegate = self
//        
//        do {
//            try frc.performFetch()
//        } catch {
//            observer.sendNotify(from: self, withMsg: "Error fetching data")
//        }
//        
//        guard frc.fetchedObjects?.count == 0 else {
//            // We have brewery entries go ahead and display them viewcontroller
//            // TODO remove this temporary code to detect if there are breweries here already
//            //fatalError()
//            return
//        }
        
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
    
    
    // Fetch breweries based on style selected.
    // Get the Brewery entries from the database
    internal func displayBreweriesWith(style : Style, completion: (_ success: Bool) -> Void){
        print("BreweryTableLISt \(#line) Requesting style: \(style.id!) ")
        let request : NSFetchRequest<Beer> = Beer.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "styleID = %@", style.id!)
        var results : [Beer]!
        // Presave the mainContext maybe that's why I cant see any results.
        beerFRC = NSFetchedResultsController(fetchRequest: request ,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        print("BreweryTableList \(#line) beerfrc delegate assigned ")
        beerFRC.delegate = self
        /*
         TODO When you select styles and favorite a brewery, go to favorites breweries and pick a style
         This frc will totally overwrite because it will detect changes in the breweries from favoriting
         forcing a reload on the mapviewcontroller.
         */
        // This must block because the mapView must be populated before it displays.
        //        container?.performBackgroundTask({
        //            (context) -> Void in
        print("BreweryTable \(#line) Context Perform is next ")
        readOnlyContext?.perform() {
            do {
                try self.beerFRC?.performFetch()
                results = (self.beerFRC?.fetchedObjects)! as [Beer]
                //results = try (thisContext!.fetch(request)) as [Beer]
                print("BreweryTableList \(#line) Are the results are zero? \(results.count) ")
            } catch {
            }
            // Now that we have Beers with that style, what breweries are associated with these beers
            // Array to hold breweries
            self.displayableBreweries.removeAll()
            print("BreweryTableList \(#line) were there any beers that matched style\n")
            for beer in results {
                guard beer.brewer != nil else {
                    fatalError()
                }
                if !self.displayableBreweries.contains(beer.brewer!) {
                    self.displayableBreweries.append(beer.brewer!)
                }
            }
            print("end of context perform")
            print("displayable breweries is available for table reload")
            // This would be an asynchronous notify.
            //self.observer.sendNotify(from: self, withMsg: "reload data")
        }
        print("BreweryTable \(#line) Context Perform just jump over all the code an will run later. ")
    }


    func registerObserver(view: Observer) {
        observer = view
    }
    
}

extension BreweryTableList: TableList {

    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        DispatchQueue.main.async {
            print("BreweryTableList \(#line) On the UITableViewCell u sent me I'm putting text on it. ")
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
        //return filteredObjects
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
        observer.sendNotify(from: self, withMsg: "reload data")
        print("BreweryTableList \(#line) There are now this many breweries \(controller.fetchedObjects?.count)")
        print("BreweryTableList \(#line) Rejected breweries \(BreweryDBClient.sharedInstance().rejectedBreweries)")
        //Datata = frc.fetchedObjects!
    }
}

