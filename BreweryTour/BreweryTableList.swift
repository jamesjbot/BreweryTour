//
//  BreweryTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, TableList , NSFetchedResultsControllerDelegate {
    
    internal var filteredObjects: [Brewery] = [Brewery]()
    internal var frc : NSFetchedResultsController<Brewery>!
    
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
                                         managedObjectContext: backgroundContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
            //print("Retrieved this many styles \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
        
        guard frc.fetchedObjects?.count == 0 else {
            // We have entries go ahead and display them viewcontroller
            //completion(true)
            return
        }
        if frc.fetchedObjects?.count == 0 {
            print("No brewery results going to get them from the database")
            // TODO Remove organic we will query the database for it
            BreweryDBClient.sharedInstance().downloadAllBreweries(isOrganic: false){
                (success) -> Void in
                if success {
                    print("Database succeeded populating")
                    do {
                        try self.frc.performFetch()
                        //self.listOfBreweries = frc.fetchedObjects! as [Brewery]
                        print("Saved this many breweries in model \(self.frc.fetchedObjects?.count)")
                        //completion(true)
                    } catch {
                        //completion(false)
                        fatalError("Fetch failed critcally")
                    }
                }
            }
        }
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
    
}
