//
//  StylesTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData
//import Foundation

class StylesTableList: NSObject, TableList , NSFetchedResultsControllerDelegate {
    
    //var data : [NSManagedObject] = [Style]()
    internal var filteredObjects: [Style] = [Style]()
    internal var frc : NSFetchedResultsController<Style>!
    
    let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext
    
    override init(){
        let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
        request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: persistentContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        do {
            try frc.performFetch()
            //print("Retrieved this many styles \(frc.fetchedObjects?.count)")
        } catch {
            fatalError()
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("StylesTableList willchange")
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        print("Styles changed object")
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("StylesTAbleList didChange")
        //Datata = frc.fetchedObjects!
    }
    
    
    func getNumberOfRowsInSection(searchText: String?) -> Int {
        //print("getNumberofrows on \(searchText)")
        guard searchText == "" else {
            return filteredObjects.count
        }
        return frc.fetchedObjects!.count
    }
    
    func filterContentForSearchText(searchText: String) -> [NSManagedObject] {
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).displayName?.lowercased().contains(searchText.lowercased()) )! } ))!
        //print("we updated the filtered contents to \(filteredObjects.count)")
        return filteredObjects
    }
    
    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
        if searchText != "" {
            //print("size:\(filteredObjects.count) want:\(indexPath.row) ")
            cell.textLabel?.text = (filteredObjects[indexPath.row]).displayName
        } else {
            cell.textLabel?.text = (frc.fetchedObjects![indexPath.row]).displayName
        }
        return cell
    }
    
}
