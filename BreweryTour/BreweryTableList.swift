//
//  BreweryTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/* 
    This is the view model backing the breweries with specified styles table on the
    main category viewcontroller.
    It initially shows nothing, waiting for a style to be selected by the
    CategoryViewController.
 */


import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, Subject {

    // MARK: Constants

    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: Variables

    fileprivate var currentlyObservingStyle: Style?
    fileprivate var observer : Observer!

    // variables for selecting breweries with a style
    fileprivate var displayableBreweries = [Brewery]()
    fileprivate var newBeers = [Beer]()


    // variable for search filtering
    internal var filteredObjects: [Brewery] = [Brewery]()

    internal var styleFRCObserver: NSFetchedResultsController<Style>!

    fileprivate var copyOfSet:[Brewery] = [] {
        didSet {
            // Automatically sort this set
            copyOfSet.sort(by: { (a: Brewery, b: Brewery) -> Bool in
                return a.name! < b.name!
            })
        }
    }


    // MARK: - Functions

    //On start up we don't have a style selected so this ViewController 
    //will be blank
    override init(){
        super.init()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        // Create a Style fetched results controller that will get updates from coredata.
        // The fetched style has the breweries embedded in brewerywithstyle NSSet
        styleFRCObserver = createFetchedResultsController(withStyleID: nil)

        // Register for context updates with Mediator
        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

    }


    private func createFetchedResultsController(withStyleID: String?) -> NSFetchedResultsController<Style> {
        let styleRequest: NSFetchRequest<Style> = Style.fetchRequest()
        styleRequest.sortDescriptors = []
        styleRequest.predicate = NSPredicate(format: "id == %@",
                                             (withStyleID ?? "") )
        let tempFRC = NSFetchedResultsController(fetchRequest: styleRequest,
                                                      managedObjectContext: readOnlyContext!,
                                                      sectionNameKeyPath: nil, cacheName: nil)
        return tempFRC
    }



    internal func prepareToShowTable() {
        // Get the currently selected style form the mediator
        // If the selection is a brewery then the CategoryViewController would have intercepted that selection
        // and stopped this program from preparing to showTable()
        currentlyObservingStyle = Mediator.sharedInstance().getPassedItem() as? Style
        styleFRCObserver = createFetchedResultsController(withStyleID: currentlyObservingStyle?.id)
        styleFRCObserver.delegate = self
        do {
            try styleFRCObserver.performFetch()
            copyOfSet = (styleFRCObserver.fetchedObjects?.first?.brewerywithstyle?.allObjects as! [Brewery]?)!
        } catch {
            NSLog("Critical error reading from coredata")
        }
    }


    // Allow CategoryViewController to register for updates.
    func registerObserver(view: Observer) {
        observer = view
    }
}


// MARK: - BreweryTableList: TableList

extension BreweryTableList: TableList {

    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        configureCell(cell: cell, indexPath: indexPath, searchText: searchText)
        return cell
    }


    private func configureCell(cell: UITableViewCell, indexPath: IndexPath, searchText: String?) {
        DispatchQueue.main.async {
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            let image = #imageLiteral(resourceName: "Nophoto.png")
            cell.imageView?.image = image
            var brewery: Brewery?
            if (searchText?.isEmpty)! {
                brewery = self.copyOfSet[indexPath.row]
            } else if !((searchText?.isEmpty)!) && self.filteredObjects.count > 0 {
                brewery = (self.filteredObjects[indexPath.row])
            }
            cell.textLabel?.text = brewery?.name
            if let data = brewery?.image {
                DispatchQueue.main.async {
                    cell.imageView?.image = UIImage(data: data as Data)
                    cell.imageView?.setNeedsDisplay()
                }
            }
            cell.setNeedsDisplay()
        }
    }


    func filterContentForSearchText(searchText: String, completion: ((_: Bool)-> ())? = nil) {
        // Only filter object if there are objects to filter.
        guard (copyOfSet.count) > 0 else {
            filteredObjects.removeAll() // Remove all of last filtered objects
            return
        }
        filteredObjects = (copyOfSet.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))
        if let completion = completion {
            completion(true)
        }
    }

    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results.
        // Fetch data because when we use the on screen segemented display to switch 
        // to this it will refresh the display, because of the back delete.
        // First thing called on a reload from category screen
        guard searchText == "" else {
            return filteredObjects.count
        }
        return (copyOfSet.count )
    }
    
    
    internal func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success : Bool, _ msg : String?) -> Void ) -> AnyObject? {
        // We are only selecting one brewery to display, so we need to remove
        // all the breweries that are currently displayed. And then turn on the selected brewery
        var savedBreweryForDisplay : Brewery!
        if searchText == "" {
            savedBreweryForDisplay = (copyOfSet[elementAt.row]) as Brewery
        } else {
            savedBreweryForDisplay = (filteredObjects[elementAt.row]) as Brewery
        }
        // Tell mediator about the brewery I want to display
        // Then mediator will tell selectedBeerList what to display
        (Mediator.sharedInstance() as MediatorBroadcastSetSelected).select(thisItem: savedBreweryForDisplay, completion: completion)
        return nil
    }

}


// MARK: - ReceiveBroadcastManagedObjectContextRefresh

extension BreweryTableList: ReceiveBroadcastManagedObjectContextRefresh {
    internal func contextsRefreshAllObjects() {
        styleFRCObserver.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            try styleFRCObserver.performFetch()
        } catch {

        }
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension BreweryTableList : NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        func updateStyleSet() {
            let style = anObject as! Style
            if style.id == currentlyObservingStyle?.id {
                copyOfSet = style.brewerywithstyle?.allObjects as! [Brewery]
            }
        }

        switch (type){
        case .insert:
            updateStyleSet()
            break
        case .delete:
            updateStyleSet()
            break
        case .move:
            break
        case .update:
            updateStyleSet()
            break
        }
    }

    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    observer.sendNotify(from: self, withMsg: Message.Reload)

    }
}









