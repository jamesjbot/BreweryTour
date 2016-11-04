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

    // MARK: Constants
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext

    // MARK: Variables
    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Style] = [Style]()
    internal var frc : NSFetchedResultsController<Style>!
    var observer : Observer!
    
    // MARK: Functions
    
    func downloadBeerStyles() {
        BreweryDBClient.sharedInstance().downloadBeerStyles(){
            (success, msg) -> Void in
            if success {
                self.observer.sendNotify(s: "We have styles")
            }
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
            fatalError()
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
        observer.sendNotify(s: "Content changed")
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        guard searchText == "" else {
            return filteredObjects.count
        }
        return frc.fetchedObjects!.count
    }
    
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).displayName?.lowercased().contains(searchText.lowercased()) )! } ))!
        return filteredObjects
    }
    
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        if searchText != "" {
            cell.textLabel?.text = (filteredObjects[indexPath.row]).displayName
        } else {
            cell.textLabel?.text = (frc.object(at: indexPath ) ).displayName
        }
        return cell
    }

    
    internal func selected(elementAt: IndexPath, searchText: String, completion:  @escaping (Bool, String?) -> Void ) -> AnyObject? {
        // With the style in hand go look for them with the BREWERYDB client and have the client mark them as must display
        var style : String
        if searchText == "" {
            style = frc.fetchedObjects![elementAt.row].id!
        } else {
            style = filteredObjects[elementAt.row].id!
        }
        
        // Tell mediator this is the style I want to display
        var aStyle : Style
        if searchText == "" {
            aStyle = frc.fetchedObjects![elementAt.row]
        } else {
            aStyle = filteredObjects[elementAt.row]
        }
        mediator.selected(thisItem: aStyle)
        
        // TODO put activity indicator animating here
        // TODO temporary bypass organic swift
        BreweryDBClient.sharedInstance().downloadBeersBy(styleID: style,
                                                         isOrganic: false,
                                                         completion: completion)
      return nil
    }
}
