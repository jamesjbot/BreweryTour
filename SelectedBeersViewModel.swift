//
//  SelectedBeersTableList.swift
//  
//
//  Created by James Jongsurasithiwat on 10/21/16.
//
//
/*
 This program is the view model for the selected beers tab.
 We create the NSFetchRequest based on what needs to be displayed on screen.
 Currently it will be either all beers or a selection of beers based on brewery or style of beer.
 The mediator will inject the search item
 The default screen before injection will show all beers.
 */

// TODO this is broken I can't search online anymore.

import UIKit
import CoreData

class SelectedBeersViewModel: BeersViewModel, Subject {

    // MARK: - Functions

    // Function to perform fetch on dynamic request.
    // After fetch is completed the user interface
    // is notified of changes with observer.notify(msg:"")
    // From then on the delegate takes over and notifies the observer of changes.
    override internal func performFetchRequestFor(observerNeedsNotification: Bool){
        print("selecttable \(#line) performFetchRequest ")
        // Set default query to AllBeers mode
        var subPredicates = [NSPredicate]()
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = [NSSortDescriptor(key: "beerName", ascending: true)]

            // Display only selected beers
            if selectedObject is Brewery {
                subPredicates.append(NSPredicate(format: "breweryID == %@",
                                                (selectedObject as! Brewery).id!))
            } else if selectedObject is Style {
                subPredicates.append(NSPredicate(format: "styleID == %@",
                                                (selectedObject as! Style).id!))
            }

        guard subPredicates.count > 0 else {
            // Therefore there was no selection don't search for anything.
            return
        }

        // Set the predicates
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)

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
                observer?.sendNotify(from: self, withMsg: "reload data")
            }
        } catch {
            observer?.sendNotify(from: self, withMsg: "Error fetching data")
        }
    }
}










