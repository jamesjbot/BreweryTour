//
//  AllBreweriesTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation

import UIKit
import CoreData

class AllBreweriesTableList: NSObject, Subject {
    
    var observer : Observer!
    
    func registerObserver(view: Observer) {
        observer = view
    }
    
    internal var mediator: NSManagedObjectDisplayable!
    internal var filteredObjects: [Brewery] = [Brewery]()
    
    // Currently watches the persistentContext
    internal var frc : NSFetchedResultsController<Brewery>!
    
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    
    let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext
    //let backgroundContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.backgroundContext
    
    override init(){
        super.init()
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        request.fetchLimit = 10000
        frc = NSFetchedResultsController(fetchRequest: request,
                                         managedObjectContext: readOnlyContext!,
                                         sectionNameKeyPath: nil,
                                         cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            observer.sendNotify(from: self, withMsg: "Error fetching data")
        }
        
        guard frc.fetchedObjects?.count == 0 else {
            // We have brewery entries go ahead and display them viewcontroller
            return
        }
        
        // Since we didn't exit trying to find  the breweries above
        // Fetch all the breweries from the internet.
        //        BreweryDBClient.sharedInstance().downloadAllBreweries() {
        //            (success, msg) -> Void in
        //            if msg == "All Pages Processed" {
        //                print("BreweryTableList \(#line) init() msg:\(msg) dbbrewery client sent back completion handlers saying success:\(success))")
        //                print("BreweryTableList \(#line) Sending CategoryView a notification to reload breweryTablelist ")
        //                self.observer.sendNotify(from: self, withMsg: "reload data")
        ////                do {
        ////                    print("BreweryTableList \(#line)BreweryTableList \(#line)Is this fetch needed?")
        ////                    try self.frc.performFetch()
        ////                } catch {
        ////                    fatalError()
        ////                }
        //            }
        //
        //        }
    }




}


extension AllBreweriesTableList: UpdateFetchedController {
    internal func contextsHaveBeenBatchDeleted() {
        do {
            try frc.managedObjectContext.refreshAllObjects()
        } catch {
        }
    }
}

extension AllBreweriesTableList : TableList {

    func cellForRowAt(indexPath: IndexPath, cell: UITableViewCell, searchText: String?) -> UITableViewCell {
            cell.textLabel?.adjustsFontSizeToFitWidth = true
            let image = #imageLiteral(resourceName: "Nophoto.png")
            cell.imageView?.image = image
            var brewery: Brewery!
            if (searchText?.isEmpty)!  {
                brewery = self.frc.object(at: indexPath)
            } else {
                brewery = self.filteredObjects[indexPath.row]
            }
            // TODO temp
            cell.detailTextLabel?.text = brewery.id!
            cell.textLabel?.text = brewery.name!
            if let data = brewery.image {
                DispatchQueue.main.async {
                    cell.imageView?.image = UIImage(data: data as Data)
                    cell.imageView?.setNeedsDisplay()
                }
            }
            cell.setNeedsDisplay()
        return cell
    }


    func getNumberOfRowsInSection(searchText: String?) -> Int {
        // If we batch delete in the background frc will not retrieve delete results.
        // Fetch data because when we use the on screen segemented display to switch to this it will refresh the display, because of the back delete.
        guard searchText == "" else {
            return filteredObjects.count
        }
        return frc.fetchedObjects!.count
    }


    func filterContentForSearchText(searchText: String) {
        // BreweryTableList Observes the persistent Context and I only saved them
        // the main context and so there are none.
        // Only filter object if there are objects to filter.
        guard frc.fetchedObjects != nil else {
            filteredObjects.removeAll()
            return
        }
        guard (frc.fetchedObjects?.count)! > 0 else {
            filteredObjects.removeAll()
            return
        }
        filteredObjects = (frc.fetchedObjects?.filter({ ( ($0 ).name?.lowercased().contains(searchText.lowercased()) )! } ))!
    }


    func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success : Bool, _ msg : String?) -> Void ) -> AnyObject? {
        // We are only selecting one brewery to display, so we need to remove
        // all the breweries that are currently displayed. And then turn on the selected brewery
        var savedBreweryForDisplay : Brewery!
        if searchText == "" {
            savedBreweryForDisplay = (frc.object(at:elementAt)) as Brewery
        } else {
            savedBreweryForDisplay = (filteredObjects[elementAt.row]) as Brewery
        }
        // Tell mediator about the brewery I want to display
        // Then mediator will tell selectedBeerList what to display
        mediator.selected(thisItem: savedBreweryForDisplay, completion: completion)
        return nil
    }    
}


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
            completion!(success,msg)
        }
    }
}


extension AllBreweriesTableList : NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("AllBreweryTableList \(#line) AllBreweriesTableList willchange")
    }
    
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        //print("AllBreweryTableList \(#line) AllBreweryTableList changed object")
        switch (type){
        case .insert:
            //print("AllBreweryTable \(#line) inserting\n\(anObject)")
            break
        case .delete:
            //print("AllBreweryTable \(#line) delete")
            break
        case .move:
            //print("AllBreweryTable \(#line) move ")
            break
        case .update:
            //print("AllBreweryTable \(#line) update ")
            break
        }
    }

    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("AllBreweryTableList \(#line) AllBreweryTableList controllerdidChangeContent notify observer")
        // TODO We're preloading breweries do I still need this notify
        // Send message to observer regardless of situation. The observer decides if it should act.
        observer.sendNotify(from: self, withMsg: "reload data")
        //print("AllBreweryTableList \(#line) According to \(controller)\n There are now this many breweries \(controller.fetchedObjects?.count)")
            //print("AllBreweryTableList \(#line) According to \(frc)\n There are now this many breweries \(frc.fetchedObjects?.count)")
        //print("AllBreweryTableList \(#line) Rejected breweries \(BreweryDBClient.sharedInstance().rejectedBreweries)")
        //Datata = frc.fetchedObjects!
    }
}

