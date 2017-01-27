//
//  BeersViewModel.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/12/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
/*
    This is the viewmodel that will back the SelectedBeersViewController
    The BeersViewModel is already setup up to pull in All Beers
    The subclass AllBeersViewModel just includes it special online search capability
    The SelectedBeersViewModel overrides the perform Fetch Request to pull in 
    either Brewery or Style.
 */

import Foundation
import UIKit
import CoreData

class BeersViewModel: NSObject {

    // MARK: - Constants

    internal let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    
    // MARK: - Variables

    fileprivate var filteredObjects: [Beer] = [Beer]()

    internal var frc : NSFetchedResultsController<Beer>! = NSFetchedResultsController()

    fileprivate var mediator:  Mediator = Mediator.sharedInstance()

    internal var observer : Observer?

    internal var selectedObject : NSManagedObject! = nil


    // MARK: - Functions 

    internal override init(){
        super.init()

        //Accept changes from other managed object contexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        // Register for deletions of all the data in Coredata
        registerForManagedObjectContextRefresh(broadcaster: mediator)

        // Register for future updates on the selected NSManagedObject
        registerForSelectedObjectObserver(broadcaster: mediator)

        // We registerd for future updates to the selected NSManagedObject but currently
        // for this initial run we must get the NSManagedObject.
        selectedObject = Mediator.sharedInstance().getPassedItem()

        // Create the generic beers FetchedResultsController
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)

        // Perform a fetch with the results on controller on the newly passedItem.
        performFetchRequestFor(observerNeedsNotification: false)

        /*
         AllBeersViewModel will use the perform fetch in this class
         SelectedBeersViewModel will use it's own performFetch function
         */
    }


    // This generic fetch will get all the beers in the data base. SelectedBeersViewModel
    // Override this method and selects based on Brewery or Style
    // Internal because the SelectedBeersViewClass need to override this
    internal func performFetchRequestFor(observerNeedsNotification: Bool){
        // Set default query to AllBeers mode
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]

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
                observer?.sendNotify(from: self, withMsg: Message.Reload)
            }
        } catch {
            observer?.sendNotify(from: self, withMsg: Message.Retry)
        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension BeersViewModel: NSFetchedResultsControllerDelegate {

    // Delegate changes occured now notify observer to reload itself
    internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Tell the SelectedBeersViewController that is registerd to refresh itself from me
        observer?.sendNotify(from: self, withMsg: Message.Reload)
    }
}


// MARK: - ReceiveBroadcastSetSelected

// When a new style or brewery is selected this method is called
extension BeersViewModel: ReceiveBroadcastSetSelected {

    // This is just a helper function to register with the mediator for updates.
    fileprivate func registerForSelectedObjectObserver(broadcaster: MediatorBroadcastSetSelected) {
        broadcaster.registerForObjectUpdate(observer: self)
    }


    internal func updateObserversSelected(item: NSManagedObject) {
        selectedObject = item
        // Start retrieving entries in the background but dont update as view
        // is not onscreen, because SelectedBeersViewController is mutually exclusive 
        // to the CategoryViewController.
        performFetchRequestFor(observerNeedsNotification: false)
    }
}


// MARK: - ReceiveBroadcastManagedObjectContextRefresh

extension BeersViewModel: ReceiveBroadcastManagedObjectContextRefresh {
    // When all coredata ManagedObjects are deleted this is called by the mediator to refresh the context
    internal func contextsRefreshAllObjects() {
        frc.managedObjectContext.refreshAllObjects()

        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try frc.performFetch()
        } catch {

        }
    }

    // Helper function to register as an obsever
    fileprivate func registerForManagedObjectContextRefresh(broadcaster: BroadcastManagedObjectContextRefresh) {
        broadcaster.registerManagedObjectContextRefresh(self)
    }
}


// MARK: - TableList

// All the methods that allow this object to function as a view model.
extension BeersViewModel: TableList {

    // Configures Tableviewcell for display
    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        configureCell(cell: cell, indexPath: indexPath, searchText: searchText)
        return cell
    }


    private func configureCell(cell: UITableViewCell, indexPath: IndexPath, searchText: String?) {
        // Set a default image
        // Depending on what data is shown populate image and text data.
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        let image = #imageLiteral(resourceName: "Nophoto.png")
        cell.imageView?.image = image
        var beer: Beer!
        if (searchText?.isEmpty)!  {
            beer = self.frc.object(at: indexPath)
        } else if !((searchText?.isEmpty)!) && self.filteredObjects.count > 0 {
            beer = self.filteredObjects[indexPath.row]
        }
        if let beerName = beer.beerName,
            let brewerName = beer.brewer?.name {
            cell.textLabel?.text = beerName
            cell.detailTextLabel?.text = brewerName
        }
        if let data = beer.image {
            DispatchQueue.main.async {
                cell.imageView?.image = UIImage(data: data as Data)
                cell.imageView?.setNeedsDisplay()
            }
        }
        DispatchQueue.main.async {
            cell.setNeedsDisplay()
        }
    }


    internal func filterContentForSearchText(searchText: String, completion: ((_: Bool)-> ())? = nil ) {
        filteredObjects.removeAll()

        guard frc.fetchedObjects != nil else {
            return
        }
        guard frc.fetchedObjects!.count > 0 else {
            return
        }

        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).beerName!.lowercased().contains(searchText.lowercased()) ) } ))!
        if let completion = completion {
            completion(true)
        }
    }


    // TableView function
    internal func getNumberOfRowsInSection(searchText: String?) -> Int {
        // Since the query is dynamic we need to refresh the data incase something changed.
        performFetchRequestFor(observerNeedsNotification: false )
        /*
         Send back filtered or unfilterd
         results, based on user having search text in the search bar.
         */
        if searchText != "" {
            return filteredObjects.count
        } else {
            return (frc.fetchedObjects?.count ?? 0)
        }
    }


    // Register the SelectedBeersViewController that will display this data
    internal func registerObserver(view: Observer) {
        observer = view
    }


    // When the user selects an item, return that item
    internal func selected(elementAt: IndexPath,
                           searchText: String,
                           completion:  @escaping (Bool, String?) -> Void) -> AnyObject? {
        if searchText != "" {
            return filteredObjects[elementAt.row]
        } else {
            return frc.fetchedObjects?[elementAt.row]
        }
    }
    
}

