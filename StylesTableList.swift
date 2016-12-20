//
//  StylesTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the view model backing the Styles switch on the main category view
 controller
 **/

import UIKit
import CoreData
import Foundation

class StylesTableList: NSObject, TableList , NSFetchedResultsControllerDelegate, Subject {
    
    // TODO Remove Debug code
    var firstRun : Bool = true
    
    
    // MARK: Constants
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext
    
    // MARK: Variables
    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Style] = [Style]()
    // Runs off of persistentContext
    internal var frc : NSFetchedResultsController<Style>!
    var observer : Observer!
    
    // MARK: Functions
    
    func downloadBeerStyles() {
        BreweryDBClient.sharedInstance().downloadBeerStyles(){
            (success, msg) -> Void in
            if success {
                self.observer.sendNotify(from: self, withMsg: "We have styles")
            } //else {
            //  self.observer.sendNotify(s: msg!)
            //}
        }
    }
    
    
    func registerObserver(view: Observer) {
        observer = view
    }
    
    
    func searchForUserEntered(searchTerm: String, completion: ( (Bool, String?) -> (Void))?) {
        // Styles are automatically downloaded on start up so searching again will not yield anything new
        completion!(false,"There are no more new styles")
    }
    
    
    override init(){
        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: persistentContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            // TODO can't send self don't know what to send then.
            //observer.sendNotify(from: self, withMsg: "Error fetching data")
        }
        super.init()
        frc.delegate = self
        downloadBeerStyles()
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    }
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        observer.sendNotify(from: self, withMsg: "reload data")
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        guard searchText == "" else {
            return filteredObjects.count
        }
        return frc.fetchedObjects!.count
    }
    
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ( $0 ).displayName?.lowercased().contains(searchText.lowercased()) )! } ))!
        return filteredObjects
    }
    
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
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        // Move this UI update to main queue.
            print("StylesTablesList \(#line) I'm updating UITableView cell on main ")
            if searchText != "" {
                cell.textLabel?.text = (filteredObjects[indexPath.row]).displayName!
            } else {
                frc.managedObjectContext.performAndWait {
                    cell.textLabel?.text = (self.frc.object(at: indexPath )).displayName!
                }
            }
        DispatchQueue.main.async {
            cell.setNeedsDisplay()
        }
        return cell
    }
    
    
    internal func selected(elementAt: IndexPath,
                           searchText: String,
                           completion:  @escaping (Bool, String?) -> Void ) -> AnyObject? {
        // With the style in hand go look for them with the BREWERYDB client and have the client mark them as must display
        //        var style : String
        //        if searchText == "" {
        //            style = frc.object(at: elementAt).id!
        //        } else {
        //            style = filteredObjects[elementAt.row].id!
        //        }
        
        // Tell mediator this is the style I want to display
        // Then mediator will tell selectedBeersList what to display.
        var aStyle : Style
        if searchText == "" {
            aStyle = frc.fetchedObjects![elementAt.row]
        } else {
            aStyle = filteredObjects[elementAt.row]
        }
        mediator.selected(thisItem: aStyle, completion: completion)
        return nil
    }
}
