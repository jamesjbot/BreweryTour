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
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext

    // MARK: Variables
    private var organic : Bool = false
    private var allBeersMode : Bool = false
    internal var selectedItemID : NSManagedObjectID = NSManagedObjectID()
    private var selectedObject : NSManagedObject! = nil
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
                                         managedObjectContext: persistentContext!,
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
    
    
    // Function that responds to changes in whether the user wants to display 
    // only organic beers
    internal func changeOrganicState(iOrganic : Bool) {
        organic = iOrganic
        performFetchRequestFor(organic: organic)
    }
    
    
    // Mediator Selector
    // The mediator tells the SelectedBeersTable what object was selected.
    internal func setSelectedItem(toNSObjectID : NSManagedObjectID) {
        // This allows the external object to set the itemID
        selectedItemID = toNSObjectID
        // This grabs the item using a global variable.
        //let object = Mediator.sharedInstance().passingItem
        
        //change object id in to object
        let object = coreDataStack?.mainContext.object(with: toNSObjectID)
        //then get stuff
        // Fetch all the beers for this object

        // TODO see this is the ambiguity on the category view controller I look for 
        // Beers and Breweries that fit for the style
        // But for here I call call the beers for brewery.
        // So I am calling this function in two places 
        // I should consolidate where I call the function from. 
        // Either it gets called in category or it gets called here.
        // Pro for callng in category
        // Calling in category will yield effectively a prefetch
        // Only brewery can be selected from the category view controller.
        
        // Con for calling in category
        // A model function is embedded in the viewcontroller
        
        // Pro for calling here
        // Simple to implement
        // Con for calling here
        // No time for loading user will have to wait
        
        // Now I've move decision making on processing brewery or style selected to the beer list 
        // Does this make sense?
        // Nope
        
        // These methods should have been called by mediator on switch why do I need them here?
        if object is Brewery {
            BreweryDBClient.sharedInstance().downloadBeersBy(brewery: object as! Brewery) {
                (success,msg) -> Void in
                self.performFetchRequestFor(organic: self.organic)
            }
        } else if object is Style {
            BreweryDBClient.sharedInstance().downloadBeersAndBreweriesBy(styleID: (object as! Style).id!,
                                                                         isOrganic: false) {
                (success,msg) -> Void in
                self.performFetchRequestFor(organic: self.organic)
            }
        }
        //performFetchRequestFor(organic: organic)
    }

    
    internal func toggleAllBeersMode() {
        allBeersMode = !allBeersMode
        print("Toggled all beers mode to \(allBeersMode)")
        performFetchRequestFor(organic: nil)
        observer.sendNotify(s: "Reload table")
    }
    
    
    // TODO remove organic parameter.
    private func performFetchRequestFor(organic : Bool?){
        // Add a selector for organic beers only.
        var subPredicates = [NSPredicate]()
        if let organic = Mediator.sharedInstance().organic {
            subPredicates.append(NSPredicate(format: "isOrganic == %@",
                                             NSNumber(value: organic) ))
            subPredicates.append(NSPredicate(format: "favorite == YES", []))
            print(subPredicates)
        }
        print("Perform fetch request called")
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        selectedObject = Mediator.sharedInstance().passingItem
        switch allBeersMode {
        case true:
            //print("All beers mode is on")
            break
        case false :
            //print("All beers mode is OFF")
            if selectedObject is Brewery {
                subPredicates.append(NSPredicate(format: "breweryID == %@",
                                                (selectedObject as! Brewery).id!))
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
                print("operating on brewery")
            } else if selectedObject is Style {
                subPredicates.append(NSPredicate(format: "styleID == %@",
                                                (selectedObject as! Style).id!))
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
                print("operating on style")
            } else {
                //print("All beers mode again default")
                break
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
    
    
    internal func mediatorPerformFetch() {
        print("mediator perform fetch called")
        performFetchRequestFor(organic : organic)
    }
  
    
    // TableView function
    internal func getNumberOfRowsInSection(searchText: String?) -> Int {
        print("getNumberofRowsInSection fetch called")
        performFetchRequestFor(organic : nil )
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
