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
    private var organic : Bool = false
    private var allBeersMode : Bool = false
    internal var selectedItemID : NSManagedObjectID = NSManagedObjectID()
    private var selectedObject : NSManagedObject! = nil
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
    
    internal func changeOrganicState(iOrganic : Bool) {
        organic = iOrganic
    }
    
    // Mediator Selections
    // The mediator tell the SelectedBeersTable what object was selected.
    internal func setSelectedItem(toNSObjectID : NSManagedObjectID) {
        selectedItemID = toNSObjectID
        // Is passing object id still needed?
        let object = Mediator.sharedInstance().passingItem
        //change object id in to object
        //then get stuff
        // TODO fetch all the beers for this object
        //if toNSObjectID\
        if object is Brewery {
            BreweryDBClient.sharedInstance().downloadBeersBy(brewery: object as! Brewery) {
                (success,msg) -> Void in
                //self.performFetchRequestFor()
            }
        }
        performFetchRequestFor(organic: organic)
    }

    
    func toggleAllBeersMode() {
        allBeersMode = !allBeersMode
        print("Toggled all beers mode to \(allBeersMode)")
        performFetchRequestFor(organic: nil)
        observer.sendNotify(s: "Reload table")
    }
    
    
    // TODO remove organic parameter.
    func performFetchRequestFor(organic : Bool?){
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
    
    
    func mediatorPerformFetch() {
        print("mediator perform fetch called")
        performFetchRequestFor(organic : nil)
    }
  
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
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
        print("SelectedBeersTableList willchange")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("SelctedBeersTableList changed object")
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("SelectedBeersTableList didChange")
        //Datata = frc.fetchedObjects!
        // Tell what ever view controller that is registerd to refresh itself from me
        //TODO
        observer.sendNotify(s: "You were updated")
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
