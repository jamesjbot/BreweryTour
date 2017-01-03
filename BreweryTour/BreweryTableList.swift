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
 It initially shows nothing, waiting for a style to be select.
 */


import Foundation
import UIKit
import CoreData

class BreweryTableList: NSObject, Subject {

    // MARK: Constants

    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: Variables
    fileprivate var currentlyObservingStyle: Style?
    var observer : Observer!

    // variables for selecting breweries with a style
    var displayableBreweries = [Brewery]()
    var newBeers = [Beer]()

    internal var mediator: NSManagedObjectDisplayable!

    // variable for search filtering
    internal var filteredObjects: [Brewery] = [Brewery]()

    internal var styleFRCObserver: NSFetchedResultsController<Style>!

    fileprivate var copyOfSet:[Brewery] = [] {
        didSet {
            // Automatically sort this set
            copyOfSet.sort(by: { (a: Brewery, b: Brewery) -> Bool in
                // TODO These were names were nil that should notbe
                return a.name! < b.name!
            })
        }
    }


    // MARK: - Functions

    //
    /*
     On start up we don't have a style selected so this ViewController will be
     blank
     */
    override init(){
        super.init()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        // Register for context updates with Mediator
        styleFRCObserver = createFetchedResultsController(withStyleID: nil)

        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        Mediator.sharedInstance().registerAsBrewryImageObserver(t: self)

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
        // Stylefetch
        currentlyObservingStyle = Mediator.sharedInstance().getPassedItem() as? Style
        styleFRCObserver = createFetchedResultsController(withStyleID: currentlyObservingStyle?.id)
        styleFRCObserver.delegate = self
        do {
            try self.styleFRCObserver.performFetch()
            copyOfSet = (styleFRCObserver.fetchedObjects?.first?.brewerywithstyle?.allObjects as! [Brewery]?)!
        } catch {
        }
        print("Prepare to show table finished")
    }


    // Allow CategoryViewController to register for updates.
    func registerObserver(view: Observer) {
        observer = view
    }
}


extension BreweryTableList: TableList {

    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        let image = #imageLiteral(resourceName: "Nophoto.png")
        cell.imageView?.image = image

        // When searchText if empty check to make sure indexpath is within set bounds
        // When searchText if full check to make sure indexpath is within set bounds
        guard (searchText?.isEmpty)! ? (indexPath.row < self.copyOfSet.count) :
            indexPath.row < self.filteredObjects.count else {
                return UITableViewCell()
        }
        var brewery: Brewery?
        if (searchText?.isEmpty)! {
            brewery = self.copyOfSet[indexPath.row]
        } else {
            brewery = (self.filteredObjects[indexPath.row])
        }
        cell.textLabel?.text = brewery?.name
        if let data = brewery?.image {
            DispatchQueue.main.async {
                cell.imageView?.image = UIImage(data: data as Data)
                cell.imageView?.setNeedsDisplay()
                print("Brewery tablelist finisehd setneedsdisplay")
            }
        }
        cell.setNeedsDisplay()
        return cell
    }


    func filterContentForSearchText(searchText: String) {
        // Only filter object if there are objects to filter.
        guard copyOfSet != nil else {
            filteredObjects.removeAll()
            return
        }
        guard (copyOfSet.count) > 0 else {
            filteredObjects.removeAll()
            return
        }
        filteredObjects = (copyOfSet.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results.
        // Fetch data because when we use the on screen segemented display to switch to this it will refresh the display, because of the back delete.
        //er crektemporaryFetchData()
        // First thing called on a reload from category screen
        guard searchText == "" else {
            print("BreweryTableList \(#line) \(#function) filtered object count \(filteredObjects.count)")
            return filteredObjects.count
        }
        return (copyOfSet.count )
        //return displayableBreweries.count
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
        Mediator.sharedInstance().selected(thisItem: savedBreweryForDisplay, completion: completion)
        return nil
    }
    

    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> (Void))?) {
        print("BreweryTableList \(#line)searchForuserEntered beer called")
        fatalError()
        // This should be block at category view controller
    }

}


extension BreweryTableList: UpdateManagedObjectContext {
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


extension BreweryTableList : NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("BreweryTableList \(#line) BreweryTableList changed object")

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
    print("BreweryTableList completed changes")
    observer.sendNotify(from: self, withMsg: "reload data")
    // Is this needed as I'm atomically doing it
    //copyOfSet = ((controller.fetchedObjects as! [Style]).first?.brewerywithstyle?.allObjects as! [Brewery]?)!
    }
}


extension BreweryTableList: BreweryAndBeerImageNotifiable {

    func tellImagesUpdate() {
        observer.sendNotify(from: self, withMsg: "reload data")
    }
}








