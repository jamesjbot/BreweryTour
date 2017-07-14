//
//  AllBreweriesTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

/*
 This object is the backing model to show all breweries.
 */

import Foundation

import UIKit
import CoreData

class AllBreweriesTableList: NSObject, Subject {

    // MARK: Constants

    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack

    internal var filteredObjects: [Brewery] = [Brewery]()

    internal var breweryFetchedResultsController : NSFetchedResultsController<Brewery>!

    fileprivate var observer : Observer?

    private let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: - Functions

    override init(){
        super.init()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.fetchLimit = 10000
        breweryFetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        breweryFetchedResultsController.delegate = self

        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        do {
            try breweryFetchedResultsController.performFetch()
        } catch {
            observer?.sendNotify(from: self, withMsg: Message.Retry)
        }

        guard breweryFetchedResultsController.fetchedObjects?.count == 0 else {
            // We have brewery entries go ahead and display them viewcontroller
            return
        }
    }

    internal func registerObserver(view: Observer) {
        observer = view
    }

}


//  MARK: - ReceiveBroadcastManagedObjectContextRefresh

extension AllBreweriesTableList: ReceiveBroadcastManagedObjectContextRefresh {

    internal func contextsRefreshAllObjects() {
        breweryFetchedResultsController.managedObjectContext.refreshAllObjects()
        breweryFetchedResultsController.managedObjectContext.reset()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try breweryFetchedResultsController.performFetch()
            observer?.sendNotify(from: self, withMsg: Message.Reload)
        } catch {

        }
    }
}


// MARK: - TableList

extension AllBreweriesTableList : TableList {

    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        configureCell(cell: cell, indexPath: indexPath, searchText: searchText)
        return cell
    }


    private func configureCell(cell: UITableViewCell, indexPath: IndexPath, searchText: String?) {
        DispatchQueue.main.async {
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            let image = #imageLiteral(resourceName: "Nophoto.png")
            cell.imageView?.image = image
            var brewery: Brewery!
            let searchEmpty = searchText?.isEmpty ?? true
            let searchNotEmpty = !searchEmpty
            if searchEmpty {
                // process the object at requested index path
                brewery = self.breweryFetchedResultsController.object(at: indexPath)
            } else if searchNotEmpty && self.filteredObjects.count > 0 {
                // process the filtered objects at requested index path
                brewery = self.filteredObjects[indexPath.row]
            }
            cell.textLabel?.text = brewery.name ?? ""

            if let data = brewery.image {
                DispatchQueue.main.async {
                    cell.imageView?.image = UIImage(data: data as Data)
                    cell.imageView?.setNeedsDisplay()
                }
            }
            cell.setNeedsDisplay()
        }
    }


    func filterContentForSearchText(searchText: String, completion: ((_ success: Bool)-> Void)? = nil ) {

        // Only filter object if there are objects to filter.
        guard breweryFetchedResultsController.fetchedObjects != nil else {
            filteredObjects.removeAll()
            return
        }
        guard (breweryFetchedResultsController.fetchedObjects?.count) ?? 0 > 0 else {
            filteredObjects.removeAll()
            return
        }
        filteredObjects = (breweryFetchedResultsController.fetchedObjects?.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))!
        if let completion = completion {
            completion(true)
        }
    }


    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results.
        // Fetch data because when we use the on screen segemented display to switch to this it will refresh the display, because of the back delete.
        guard searchText == "" else {
            return filteredObjects.count
        }
        return breweryFetchedResultsController.fetchedObjects?.count ?? 0
    }


    func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success : Bool, _ msg : String?) -> Void ) -> AnyObject? {
        // We are only selecting one brewery to display, so we need to remove
        // all the breweries that are currently displayed. And then turn on the selected brewery
        var savedBreweryForDisplay : Brewery!
        if searchText == "" {
            savedBreweryForDisplay = (breweryFetchedResultsController.object(at:elementAt)) as Brewery
        } else {
            savedBreweryForDisplay = (filteredObjects[elementAt.row]) as Brewery
        }
        // Tell mediator about the brewery I want to display
        // Then mediator will tell selectedBeerList what to display
        (Mediator.sharedInstance() as MediatorBroadcastSetSelected).select(thisItem: savedBreweryForDisplay, state: nil, completion: completion)
        return nil
    }
}


// MARK: - OnlineSearchCapable

extension AllBreweriesTableList: OnlineSearchCapable {
    // When the user has typed out and pressed done in the search bar.
    // this is the function that gets called
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> (Void))?) {
        // Calling this will invoke the downloadBreweryByBreweryName process
        // The process will immediately call back say the process started.
        BreweryDBClient.sharedInstance().downloadBreweryBy(name: searchTerm) {
            (success, msg) -> Void in
            // Send a completion regardless.
            // if there are updates later NSFetchedResultsControllerDelegate will inform the viewcontroller.
            completion?(success,msg)
        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension AllBreweriesTableList : NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Send message to observer regardless of situation. The observer decides if it should act.
        observer?.sendNotify(from: self, withMsg: Message.Reload)

    }
}






