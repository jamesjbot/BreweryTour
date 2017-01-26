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

    private let initialDelay = 1000 // 1 second
    private let longDelay = 10000 // 10 seconds
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext

    // MARK: Variables

    private var bounceDelay: Int = 0 // 10

    // Hold the brewery from the style object
    fileprivate var copyOfSet:[Brewery] = []

    fileprivate var currentlyObservingStyle: Style?

    fileprivate var debouncedFunction: (()->())? = nil

    // variables for selecting breweries with a style
    fileprivate var displayableBreweries = [Brewery]()

    // variable for search filtering
    internal var filteredObjects: [Brewery] = [Brewery]()

    fileprivate var observer : Observer!

    internal var styleFRCObserver: NSFetchedResultsController<Style>!


    // MARK: - Functions

    fileprivate func copySetAndDebounceSort(breweries: [Brewery]) {
        copyOfSet = breweries
        debouncedFunction!()
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

    // This function will drop the excessive calls sort
    // Borrowed from
    // http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call/33794262#33794262
    private func debounce(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
        var lastFireTime = DispatchTime.now()
        let dispatchDelay = DispatchTimeInterval.milliseconds(delay)

        return {
            let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
            queue.asyncAfter(deadline: dispatchTime, execute: {
                let when: DispatchTime = lastFireTime + dispatchDelay
                let now = DispatchTime.now()
                if now.rawValue >= when.rawValue {
                    lastFireTime = DispatchTime.now()
                    action()
                }
            })
        }
    }


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

        // Initialize debounce function and associate it with sortanddisplay
        bounceDelay = initialDelay
        debouncedFunction = debounce(delay: bounceDelay, queue: DispatchQueue.main, action: {
            self.sortSet()
        })
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
            if let breweries = styleFRCObserver.fetchedObjects?.first?.brewerywithstyle?.allObjects as? [Brewery] {
                copySetAndDebounceSort(breweries: breweries)
            }
        } catch {
            NSLog("Critical error reading from coredata")
        }
    }


    // Allow CategoryViewController to register for updates.
    func registerObserver(view: Observer) {
        observer = view
    }


    private func sortSet() {
        copyOfSet.sort(by: { (a: Brewery, b: Brewery) -> Bool in
            return a.name! < b.name!
        })
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
        (Mediator.sharedInstance() as MediatorBroadcastSetSelected).select(thisItem: savedBreweryForDisplay,
                                                                           state: nil,
                                                                           completion: completion)
        return nil
    }

}


// MARK: - NSFetchedResultsControllerDelegate

extension BreweryTableList : NSFetchedResultsControllerDelegate {

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if let breweries = (controller.fetchedObjects?.first as? Style)?.brewerywithstyle?.allObjects as? [Brewery] {
            copySetAndDebounceSort(breweries: breweries)
        }
        observer.sendNotify(from: self, withMsg: Message.Reload)

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
            NSLog("failed to fetch on context refresh")
        }
    }
}












