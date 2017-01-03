//
//  SelectedBeersTableList.swift
//  
//
//  Created by James Jongsurasithiwat on 10/21/16.
//
//
/*
 This program is the view model for the selected beers tab.
 We create the NSFetchRequest based on what needs to be displayed on screen.
 Currently it will be either all beers or a selection of beers based on brewery or style of beer.
 The mediator will inject the search item
 The default screen before injection will show all beers.
 */

import UIKit
import CoreData

class SelectedBeersTableList : NSObject, Subject {

    // MARK: Constants

    let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: Variables

    private var allBeersMode : Bool = false
    internal var selectedObject : NSManagedObject! = nil
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Beer] = [Beer]()
    internal var frc : NSFetchedResultsController<Beer>! = NSFetchedResultsController()
    fileprivate var observer : Observer?


    // MARK: Functions
    
    // Initialization to create a an NSFetchRequest we can use later.
    // The default query is for ALLBEERS sorted by beer name
    internal override init(){
        super.init()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)

        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)


        // No need to fetch or set delegate
        // this will happen when SelectedBeerViewController launches
        // it will call toggleBeersMode() whichCalls performFetch()
    }

    
    // Register the ViewController that will display this data
    internal func registerObserver(view: Observer) {
        observer = view
    }
    
    
    // Mediator Selector
    // The mediator tells the SelectedBeersTable what object was selected.
    internal func setSelectedItem(toNSObject : NSManagedObject) {
        selectedObject = toNSObject
        // Start retrieving entries in the background but dont update as view 
        // is not onscreen.
        performFetchRequestFor(observerNeedsNotification: false)
    }


    /*
     Toggles between showing all beers or just selected beers based on brewery or style.
     We are already on the viewcontroller to be able to toggle this, so we need
     to performFetch now.
     */
    internal func setAllBeersModeONThenperformFetch(_ control : Bool) {
        if control {
            allBeersMode = true
        } else {
            allBeersMode = false
        }
        performFetchRequestFor(observerNeedsNotification: true)
    }
    

    // Function to perform fetch on dynamic request.
    // After fetch is completed the user interface
    // is notified of changes with observer.notify(msg:"")
    // From then on the delegate takes over and notifies the observer of changes.
    fileprivate func performFetchRequestFor(observerNeedsNotification: Bool){

        // Set default query to AllBeers mode
        var subPredicates = [NSPredicate]()
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        
        // Adds additional NSPredicates to narrow selection
        switch allBeersMode {
        case true:
            // Display all beers from breweries and styles that are on the device
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
            // If neither of the above is selected it will default to all beers mode
            break
        }

        guard subPredicates.count > 0 else {
            // Therefore there was no selection don't search for anything.
            return
        }

        // Set the predicates
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)

        // Create a new fetchedresultscontroller
        frc = NSFetchedResultsController(fetchRequest : request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        //reassign the delegate
        frc.delegate = self

        do {
            try frc.performFetch()
            if observerNeedsNotification {
                observer?.sendNotify(from: self, withMsg: "reload data")
            }
        } catch {
            observer?.sendNotify(from: self, withMsg: "Error fetching data")
        }
    }
}

extension SelectedBeersTableList: UpdateManagedObjectContext {
    internal func contextsRefreshAllObjects() {
        frc.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try frc.performFetch()
        } catch {

        }
    }
}

extension SelectedBeersTableList: NSFetchedResultsControllerDelegate {
    

    // Delegate changes recorded notify observer to reload itself
    internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Tell what ever view controller that is registerd to refresh itself from me
        observer?.sendNotify(from: self, withMsg: "You were updated")
    }
}


extension SelectedBeersTableList : TableList {

    // Configures Tableviewcell for display
    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        // Set a default image
        // Depending on what data is shown populate image and text data.
        var im =  UIImage(named: "Nophoto.png")
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        if searchText != "" { // If there is something in searchText use filteredObject
            if let data : NSData = (filteredObjects[indexPath.row]).image {
                im = UIImage(data: data as Data)
            }
            cell.textLabel?.text = (filteredObjects[indexPath.row]).beerName
            cell.detailTextLabel?.text = (filteredObjects[indexPath.row]).brewer?.name
        } else { // Use unfilteredObjects
            if let data : NSData = (frc.object(at: indexPath).image) {
                im = UIImage(data: data as Data)
            }
            cell.textLabel?.text = frc.object(at: indexPath).beerName
            cell.detailTextLabel?.text = frc.object(at: indexPath).brewer?.name
        }
        cell.imageView?.image = im
        return cell
    }


    internal func filterContentForSearchText(searchText: String) {// -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).beerName!.lowercased().contains(searchText.lowercased()) ) } ))!
    }


    // TableView function
    internal func getNumberOfRowsInSection(searchText: String?) -> Int {
        // Since the query is dynamic we need to refresh the data incase something changed.
        performFetchRequestFor(observerNeedsNotification: false )
        /*
         On SelectedBeers ViewController we have two selections
         The segmentedControl is serviced by the IBAction attached to the
         segmentedcontrol. While here we send back filtered or unfilterd
         results, based on user having search text in the search bar.
         */
        if searchText != "" {
            return filteredObjects.count
        } else {
            return (frc.fetchedObjects?.count ?? 0)
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
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                try self.frc.performFetch()
                self.observer?.sendNotify(from: self, withMsg: "Reload data")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
            }
        }
    }
    
}
