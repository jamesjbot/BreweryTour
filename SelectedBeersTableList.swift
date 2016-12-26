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

class SelectedBeersTableList : NSObject , NSFetchedResultsControllerDelegate, Subject {

    // MARK: Constants
    // let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext
    //let mainContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.mainContext

    // MARK: Variables
    fileprivate var organic : Bool = false
    private var allBeersMode : Bool = false
    //internal var selectedItemID : NSManagedObjectID = NSManagedObjectID()
    internal var selectedObject : NSManagedObject! = nil
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Beer] = [Beer]()
    // This currently runs off of mainContext
    internal var frc : NSFetchedResultsController<Beer>!

    fileprivate var observer : Observer!
    
    // MARK: Functions
    
    // Initialization to create a an NSFetchRequest we can use later.
    // The default query is for all beers sorted by beer name
    internal override init(){
        super.init()
        readOnlyContext?.automaticallyMergesChangesFromParent = true
        print("SelectedBeersTable \(#line) initializer called ")
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            // TODO can't send self then don't know what to send
            //observer.sendNotify(from: self, withMsg: "Error fetching data.")
        }
        print("SelectedBeersTable \(#line) initializer completed ")
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
        print("SelectedBeersTable \(#line) told what was selected.")
        selectedObject = toNSObject
    }

    // Toggles between showing all beers or just selected beers based on brewery or style.
    internal func toggleAllBeersMode(control : UISegmentedControl) {
        switch control.selectedSegmentIndex {
        case 0: // Selected Beers
            allBeersMode = false
        case 1: // All Beers
            allBeersMode = true
        default:
            break
        }
        print("SelectedBeersTableList \(#line)Toggled all beers mode to \(allBeersMode)")
        performFetchRequestFor(organic: organic, observerNeedsNotification: true)
    }
    

    // Function to perform fetch on dynamic request.
    // After fetch is completed the user interface
    // needs to be notified of changes with observer.notify(msg:"")
    // Who is a good test brewery for organic beers
    fileprivate func performFetchRequestFor(organic : Bool, observerNeedsNotification: Bool){
        print("SelectedBeersTable \(#line) performFetchRequest called on MainContext ")
        // Add a selector for organic beers only.
        var subPredicates = [NSPredicate]()
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
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
            print("SelectedBeersTable \(#line) Fetch Performed results: \(frc.fetchedObjects?.count) ")
            if observerNeedsNotification {
                observer.sendNotify(from: self, withMsg: "reload data")
            }
        } catch {
            observer.sendNotify(from: self, withMsg: "Error fetching data")
        }
    }
    
    
    internal func mediatorPerformFetch() {
        print("SelectedBeersTableList \(#line) mediatorPerformFetch called")
        performFetchRequestFor(organic : organic, observerNeedsNotification: true)
    }
  
    

    
    

    
    
//    internal func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        print("SelectedBeersTableList \(#line)SelectedBeersTableList willchange")
//    }
//    
//    
//    internal func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        print("SelectedBeersTableList \(#line)SelctedBeersTableList changed object")
//    }
    
    
    internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Tell what ever view controller that is registerd to refresh itself from me
        observer.sendNotify(from: self, withMsg: "You were updated")
    }

    

}
extension SelectedBeersTableList : TableList {

    // Configures Tableviewcell for display
    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        // Set a default image
        // Depending on what data is shown populate image and text data.
        var im =  UIImage(named: "Nophoto.png")
        if searchText != "" { // If there is something in searchText use filteredObject
            if let data : NSData = (filteredObjects[indexPath.row]).image {
                im = UIImage(data: data as Data)
            }
            cell.textLabel?.text = (filteredObjects[indexPath.row]).beerName
            cell.detailTextLabel?.text = (filteredObjects[indexPath.row]).brewer?.name
        } else { // Use unfilteredObjects
            if let data : NSData = (self.frc.object(at: indexPath).image) {
                im = UIImage(data: data as Data)
            }
            cell.textLabel?.text = self.frc.object(at: indexPath).beerName
            cell.detailTextLabel?.text = self.frc.object(at: indexPath).brewer?.name
        }
        cell.imageView?.image = im
        return cell
    }


    internal func filterContentForSearchText(searchText: String) {// -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).beerName!.lowercased().contains(searchText.lowercased()) ) } ))!
        //return filteredObjects
    }


    // TableView function
    internal func getNumberOfRowsInSection(searchText: String?) -> Int {
        print("SelectedBeersTableList \(#line) getNumberofRowsInSection fetch called")
        // Since the query is dynamic we need to refresh the data incase something changed.
        performFetchRequestFor(organic : organic, observerNeedsNotification: false )
        print("SelectedBeersTableList \(#line) selectedbeerstablelist getnumberof rows called")
        /*
         On SelectedBeers ViewController we have two selections
         The segmentedControl is serviced by the IBAction attached to the
         segmentedcontrol. While here we send back filtered or unfilterd
         results, based on user having search text in the search bar.
         */
        if searchText != "" {
            print("SelectedBeersTableList \(#line) searched filtered beers \(filteredObjects.count)")
            return filteredObjects.count
        } else {
            print("SelectedBeersTableList \(#line) searched all beers \(frc.fetchedObjects?.count)")
            return (frc.fetchedObjects?.count)!
        }
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
    
    
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> Void)?) {
        BreweryDBClient.sharedInstance().downloadBeersBy(name: searchTerm) {
            (success, msg) -> Void in
            print("SelectedBeersTableList \(#line)Returned from getting beers")
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                print("SelectedBeersTableList \(#line)Searchforuserentered performfetchcalled")
                try self.frc.performFetch()
                self.observer.sendNotify(from: self, withMsg: "Reload data")
                print("SelectedBeersTableList \(#line)Saved this many beers in model \(self.frc.fetchedObjects?.count)")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
            }
        }
    }
    
}
