//
//  SelectedBeersTableList.swift
//  
//
//  Created by James Jongsurasithiwat on 10/21/16.
//
//

import UIKit
//import Foundation
import CoreData

class SelectedBeersTableList : NSObject, TableList , NSFetchedResultsControllerDelegate, Subject {
    

    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool) -> Void)?) {
        print("Don't call this here \(#file) \(#line)")
        fatalError()
    }

    
    internal func searchForUserEntered(searchTerm: String) {
        fatalError("You should call this from your context currently")
    }
    
    var selectedItem : NSManagedObjectID = NSManagedObjectID()
    
    private var display : UIViewController!
    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Beer] = [Beer]()
    internal var frc : NSFetchedResultsController<Beer>!
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext
    
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
            //print("Retrieved this many styles \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
    }
    
    func setSelectedItem(toNSObjectID : NSManagedObjectID) {
        selectedItem = toNSObjectID
    }

    func performFetchRequestFor(){
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        if selectedItem is Brewery {
            request.predicate = NSPredicate(format: "breweryID == %@", (selectedItem as! Brewery).id!)
        } else if selectedItem is Style {
            request.predicate = NSPredicate(format: "styleID == %@", (selectedItem as! Style).id!)
        }
        frc = NSFetchedResultsController(fetchRequest : request,
                                         managedObjectContext: persistentContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
            //print("Retrieved this many styles \(frc.fetchedObjects?.count)")
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
        return [NSManagedObject]()
    }
    
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        if searchText != "" {
            cell.textLabel?.text = (filteredObjects[indexPath.row]).beerName
        } else {
            cell.textLabel?.text = (frc.fetchedObjects?[indexPath.row])?.beerName
        }
        return cell
    }
    
    internal func selected(elementAt: IndexPath, searchText: String, completion:  @escaping (Bool) -> Void) {
        print("currently unused")
        fatalError()
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
        // Tell what ever view controller that is registerd to refresh itself from me
        //TODO
        observer.sendNotify(s: "You were updated")
    }

    
    func accept(view: UIViewController){
        display = view
    }
    

    
}
