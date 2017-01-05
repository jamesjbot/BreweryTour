//
//  StylesTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This is the view model backing the Styles switch on the main category view
 controller
 
 
 Initialization Path
 CategoryViewController will initialize this
 
 
 

 */

import UIKit
import CoreData
import Foundation

class StylesTableList: NSObject {

    
    // MARK: Constants

    let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: Variables
    
    //internal var mediator: NSManagedObjectDisplayable!
    fileprivate var filteredObjects: [Style] = [Style]()
    fileprivate var frc : NSFetchedResultsController<Style>!
    var observer : Observer!


    // MARK: Functions

    internal func element(at index: Int) -> Style {
        return frc.fetchedObjects![index]
    }

    internal override init(){
        super.init()
        //Accept changes from backgroundContexts
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            fatalError("Critical coredata read failure")
        }
        frc.delegate = self

        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        // Only download styles when there are no styles in the database
        if frc.fetchedObjects?.count == 0 {
            downloadBeerStyles()
        }
    }

     
    private func refetchData() {
        do {
            try frc.performFetch()
        } catch {
            fatalError("Critical coredata read failure")
        }
    }

    // This is the inital styles populate on a brand new startup
    // This is performed in the background on initialization
    fileprivate func downloadBeerStyles() {
        BreweryDBClient.sharedInstance().downloadBeerStyles(){
            (success, msg) -> Void in
            if !success {
                self.observer.sendNotify(from: self, withMsg: "Failed to download initial styles\ncheck network connection and try again.")
            } else {
                // Added performFetch otherwise dat would not reload when there is a
                // refreshAllObjects in the context.
                self.refetchData()
                self.observer.sendNotify(from: self, withMsg: "reload data")
            }
        }
    }
}


extension StylesTableList: UpdateManagedObjectContext {

    internal func contextsRefreshAllObjects() {
        frc.managedObjectContext.refreshAllObjects()
        // Always keep this view populated with data
        downloadBeerStyles()

    }

}


extension StylesTableList: Subject {
    
    internal func registerObserver(view: Observer) {
        observer = view
    }
}



extension StylesTableList: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }

    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer.sendNotify(from: self, withMsg: "reload data")
    }
}


extension StylesTableList : TableList {

    /*
     * 2 Adambier
     * 34 Aged beer
     * 24 American style amber low calorie
     * 163 American style amber lager
     * 1905 American style amber red/ale
     * 583 American style barley wine
     * 609 American style black ale
     * 1389 American style brown ale
     * 415 American style cream ale
     * 123 American style dark lager.
     * 3 American style ice lager
     * 232 American Style imperial porter
     * 1353 American style imperial stout
     * 5519 American style india pale ale
     */
    internal func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        // Move this UI update to main queue.
            cell.imageView?.image = nil
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            assert(indexPath.row < (self.frc.fetchedObjects?.count)!)
            if (searchText?.isEmpty)! {
                // TODO it's reading nil here for some reason.
                // How do i replicate
                cell.textLabel?.text = ( (self.frc.object(at: indexPath )).displayName! + " " + ((self.frc.object(at: indexPath)).brewerywithstyle?.count.description)! + " Breweries")  ?? "Error"
            } else {
                cell.textLabel?.text = (self.filteredObjects[indexPath.row]).displayName ?? "Error"
            }
            //cell.setNeedsDisplay()
        return cell
    }
    
    
    internal func filterContentForSearchText(searchText: String) {
        guard frc.fetchedObjects != nil else {
            filteredObjects.removeAll()
            return
        }
        guard (frc.fetchedObjects?.count)! > 0 else {
            filteredObjects.removeAll()
            return
        }
        filteredObjects = (frc.fetchedObjects?.filter({ ( ( $0 ).displayName?.lowercased().contains(searchText.lowercased()) )! } ))!
    }
    
    
    internal func getNumberOfRowsInSection(searchText: String?) -> Int {
        guard searchText == "" else {
            return filteredObjects.count
        }
        return frc.fetchedObjects!.count
    }
    
    
    internal func selected(elementAt: IndexPath,
                           searchText: String,
                           completion:  @escaping (Bool, String?) -> Void ) -> AnyObject? {
        // Tell mediator this is the style I want to display
        // Then mediator will tell selectedBeersList what to display.
        var aStyle : Style
        if searchText == "" {
            aStyle = frc.fetchedObjects![elementAt.row]
        } else {
            aStyle = filteredObjects[elementAt.row]
        }
        // Temporarily set Mediator thru its protocol
        (Mediator.sharedInstance() as MediatorBroadcastSetSelected).select(thisItem: aStyle, completion: completion)
        return nil
    }
    
}
