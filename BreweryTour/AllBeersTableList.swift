//
//  AllBeersTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 11/2/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This program is the view model for the showing all beers in selected beers tab.
 **/

import Foundation
import UIKit
import CoreData

class AllBeersTableList : NSObject, TableList , NSFetchedResultsControllerDelegate, Subject {
    
    // MARK: Constants
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext
    
    // MARK: Variables
    
    var selectedItem : NSManagedObjectID = NSManagedObjectID()
    
    private var display : UIViewController!
    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Beer] = [Beer]()
    internal var frc : NSFetchedResultsController<Beer>!
    
    var observer : Observer!
    
    // MARK: Functions
    
    func registerObserver(view: Observer) {
        observer = view
    }
    
    
    override init(){
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: persistentContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            fatalError()
        }
    }
    
    func setSelectedItem(toNSObjectID : NSManagedObjectID) {
        selectedItem = toNSObjectID
        performFetchRequestFor()
    }
    
    func performFetchRequestFor(){
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest : request,
                                         managedObjectContext: persistentContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            fatalError()
        }
        
    }
    
    
    func mediatorPerformFetch() {
        performFetchRequestFor()
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        if searchText != "" {
            return filteredObjects.count
        } else {
            return (frc.fetchedObjects?.count)!
        }
    }
    
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).beerName!.lowercased().contains(searchText.lowercased()) ) } ))!
        return filteredObjects
    }
    
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        if searchText != "" {
            cell.textLabel?.text = (filteredObjects[indexPath.row]).beerName
            cell.detailTextLabel?.text = (filteredObjects[indexPath.row]).brewer?.name
            if let data : NSData = (filteredObjects[indexPath.row]).image {
                let im = UIImage(data: data as Data)
                cell.imageView?.image = im
            }
        } else {
            cell.textLabel?.text = (frc.fetchedObjects?[indexPath.row])?.beerName
            cell.detailTextLabel?.text = frc.fetchedObjects?[indexPath.row].brewer?.name
            if let data : NSData = (frc.fetchedObjects?[indexPath.row].image) {
                let im = UIImage(data: data as Data)
                cell.imageView?.image = im
            }
        }
        return cell
    }
    
    
    internal func selected(elementAt: IndexPath,
                           searchText: String,
                           completion:  @escaping (Bool, String?) -> Void) -> AnyObject? {
        if searchText != "" {
            return filteredObjects[elementAt.row]
        } else {
            return frc.fetchedObjects?[elementAt.row]
        }
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("BreweryTableList willchange")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("Brewery changed object")
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Brewery TableList didChange")
        // Datata = frc.fetchedObjects!
        // Tell what ever view controller that is registerd to refresh itself from me
        // TODO
        observer.sendNotify(s: "You were updated")
    }
    
    
    func accept(view: UIViewController){
        display = view
    }
    
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> Void)?) {
        // Search not enabled on beers tabs
        // TODO someday add
        completion!(false,"Search not enabled on this function")
    }
    
}

