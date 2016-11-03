//
//  SelectedBeersTableList.swift
//  
//
//  Created by James Jongsurasithiwat on 10/21/16.
//
//
/** This program is the view model for the selected beers tab.
 **/

import UIKit
import CoreData

class SelectedBeersTableList : NSObject, TableList , NSFetchedResultsControllerDelegate, Subject {

    // MARK: Constants
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext

    // MARK: Variables
    var allBeersMode : Bool = false
    var selectedItemID : NSManagedObjectID = NSManagedObjectID()
    var selectedObject : NSManagedObject! = nil
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
        selectedItemID = toNSObjectID
        performFetchRequestFor()
    }

    
    func toggleAllBeersMode() {
        allBeersMode = !allBeersMode
        print("Toggled all beers mode to \(allBeersMode)")
        performFetchRequestFor()
        observer.sendNotify(s: "Reload table")
    }
    
    
    func performFetchRequestFor(){
        print("Perform fetch request called")
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        selectedObject = Mediator.sharedInstance().passingItem
        switch allBeersMode {
        case true:
            print("All beers mode is on")
            break
        case false :
            print("All beers mode is OFF")
            if selectedObject is Brewery {
                request.predicate = NSPredicate(format: "breweryID == %@", (selectedObject as! Brewery).id!)
                print("operating on brewery")
            } else if selectedObject is Style {
                request.predicate = NSPredicate(format: "styleID == %@", (selectedObject as! Style).id!)
                print("operating on style")
            } else {
                print("I don't know what this selected item is \(selectedObject)                \(selectedObject is Brewery)")
            }
            break
        }

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
        performFetchRequestFor()
        print("selectedbeerstablelist getnumberof rows called")
        if searchText != "" {
            print("searched filtered object \(filteredObjects.count)")
            return filteredObjects.count
        } else {
            print("searched all object \(frc.fetchedObjects?.count)")
            return (frc.fetchedObjects?.count)!
        }
    }
    
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).beerName!.lowercased().contains(searchText.lowercased()) ) } ))!
        return filteredObjects
    }
    
    
    // Configures Tableviewcell for display
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        // Set a default image
        // Depending on what data is shown populate image and text data.
        var im =  UIImage(named: "Nophoto.png")
        if searchText != "" {
            if let data : NSData = (filteredObjects[indexPath.row]).image {
                im = UIImage(data: data as Data)
            }
            cell.textLabel?.text = (filteredObjects[indexPath.row]).beerName
            cell.detailTextLabel?.text = (filteredObjects[indexPath.row]).brewer?.name
        } else {
            if let data : NSData = (self.frc.object(at: indexPath).image) {
                im = UIImage(data: data as Data)
            }
            cell.textLabel?.text = self.frc.object(at: indexPath).beerName
            cell.detailTextLabel?.text = self.frc.object(at: indexPath).brewer?.name
        }
        cell.imageView?.image = im
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
        //Datata = frc.fetchedObjects!
        // Tell what ever view controller that is registerd to refresh itself from me
        //TODO
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
