//
//  SelectedBeersTableList.swift
//  
//
//  Created by James Jongsurasithiwat on 10/21/16.
//
//
/** This program is the view model for the selected beers tab.
    We create the NSFetchRequest based on what needs to be displayed on screen.
 Currently it will be either all beers or selection of beers based on brewery or style of beer.
 **/

import UIKit
import CoreData

class SelectedBeersTableList : NSObject, TableList , NSFetchedResultsControllerDelegate, Subject {

    // MARK: Constants
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    let mainContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.mainContext

    // MARK: Variables
    private var organic : Bool = false
    private var allBeersMode : Bool = false
    //internal var selectedItemID : NSManagedObjectID = NSManagedObjectID()
    internal var selectedObject : NSManagedObject! = nil
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Beer] = [Beer]()
    internal var frc : NSFetchedResultsController<Beer>!

    private var observer : Observer!
    
    // MARK: Functions
    
    // Initialization to create a an NSFetchRequest we can use later.
    // The default query is for all beers sorted by beer name
    internal override init(){
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: mainContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            fatalError()
        }
    }
    
    
    // Register the ViewController that will display this data
    internal func registerObserver(view: Observer) {
        observer = view
    }
    
    
    // Respond to user interface (only) changes on displaying organic beers.
    internal func changeOrganicState(iOrganic : Bool) {
        organic = iOrganic
        performFetchRequestFor(organic: organic,observerNeedsNotification: true)
    }
    
    
    // Mediator Selector
    // The mediator tells the SelectedBeersTable what object was selected.
    internal func setSelectedItem(toNSObject : NSManagedObject) {
        selectedObject = toNSObject
    }

    // TODO Decides on whether to display all data or not
    // Needs organic tag.
    internal func toggleAllBeersMode(control : UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0: // Selected Beers
            allBeersMode = false
        case 1: // All Beers
            allBeersMode = true
        default:
            break
        }
        print("Toggled all beers mode to \(allBeersMode)")
        performFetchRequestFor(organic: organic, observerNeedsNotification: true)
    }
    
    
    // TODO remove organic parameter.
    // Function to perform fetch on dynamic request.
    // After fetch is completed the user interface
    // needs to be notified of changes with observer.notify(msg:"")
    private func performFetchRequestFor(organic : Bool, observerNeedsNotification: Bool){
        // Add a selector for organic beers only.
        var subPredicates = [NSPredicate]()
        if organic == true {
            subPredicates.append(NSPredicate(format: "isOrganic == %@",
                                             NSNumber(value: organic) ))
            // TODO Test code to see what is wrong with predicates maybe
            //subPredicates.append(NSPredicate(format: "favorite == YES", []))
            print("predicates \(subPredicates)")
        }
        print("Perform fetch request called")
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        
        // Adds additional NSPredicates
        switch allBeersMode {
        case true:
            // Display all beers from breweries and styles
            break
        case false :
            // Display only selected beers
            if selectedObject is Brewery {
                subPredicates.append(NSPredicate(format: "breweryID == %@",
                                                (selectedObject as! Brewery).id!))
            } else if selectedObject is Style {
                subPredicates.append(NSPredicate(format: "styleID == %@",
                                                (selectedObject as! Style).id!))
            }
            break
        }
        // Set all predicates
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
        // Create a new fetchedresultscontroller
        frc = NSFetchedResultsController(fetchRequest : request,
                                         managedObjectContext: mainContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
            if observerNeedsNotification {
                observer.sendNotify(s: "reload data")
            }
        } catch {
            fatalError()
        }
    }
    
    
    internal func mediatorPerformFetch() {
        print("mediator perform fetch called")
        performFetchRequestFor(organic : organic, observerNeedsNotification: true)
    }
  
    
    // TableView function
    internal func getNumberOfRowsInSection(searchText: String?) -> Int {
        print("getNumberofRowsInSection fetch called")
        // Since the query is dynamic we need to refresh the data incase something changed.
        performFetchRequestFor(organic : organic, observerNeedsNotification: false )
        print("selectedbeerstablelist getnumberof rows called")
        if searchText != "" {
            print("searched filtered object \(filteredObjects.count)")
            return filteredObjects.count
        } else {
            print("searched all object \(frc.fetchedObjects?.count)")
            return (frc.fetchedObjects?.count)!
        }
    }
    

    // Configures Tableviewcell for display
    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
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
    
    
    internal func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("SelectedBeersTableList willchange")
    }
    
    
    internal func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("SelctedBeersTableList changed object")
    }
    
    
    internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("SelectedBeersTableList didChange")
        //Datata = frc.fetchedObjects!
        // Tell what ever view controller that is registerd to refresh itself from me
        //TODO
        observer.sendNotify(s: "You were updated")
    }

    
    internal func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).beerName!.lowercased().contains(searchText.lowercased()) ) } ))!
        return filteredObjects
    }
    
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> Void)?) {
        BreweryDBClient.sharedInstance().downloadBeersBy(name: searchTerm) {
            (success, msg) -> Void in
            print("Returned from getting beers")
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                print("Searchforuserentered performfetchcalled")
                try self.frc.performFetch()
                self.observer.sendNotify(s: "Reload data")
                print("Saved this many beers in model \(self.frc.fetchedObjects?.count)")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
                fatalError("Fetch failed critcally")
            }
        }
    }
    
}
