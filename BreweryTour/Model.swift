//
//  Model.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/18/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class Model {
    
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    
    //private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    
    public var singleBeer : Beer?
    public var singleBrewery : Brewery?
    public var listOfBreweries : [Brewery]?
    public var listOfBeers : [Beer]?
    public var listOfStyles : [Style]?
    
    // MARK: Functions
    
    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> Model {
        struct Singleton {
            static var sharedInstance = Model()
        }
        return Singleton.sharedInstance
    }
    
    
    internal func getListOfBreweries(onlyOrganic : Bool,
                                     completion: @escaping(_ compelte: Bool ) -> Void) {
        fatalError()
        // Get all the breweries from coredata
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        if onlyOrganic {
            request.predicate = NSPredicate(format: "hasOrganic == true")
        }
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: (coreDataStack?.backgroundContext)!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        do {
            try frc.performFetch()
            listOfBreweries = frc.fetchedObjects! as [Brewery]
        } catch {
            completion(false)
            fatalError("Fetch failed critcally")
        }
        
        guard frc.fetchedObjects?.count == 0 else {
            // We have entries go ahead and display them viewcontroller
            completion(true)
            return
        }
        
        if frc.fetchedObjects?.count == 0 {
            print("No brewery results going to get them from the database")
            // TODO Remove organic we will query the database for it
            BreweryDBClient.sharedInstance().downloadAllBreweries(isOrganic: false){
                (success) -> Void in
                if success {
                    print("Database succeeded populating")
                    do {
                        try frc.performFetch()
                        self.listOfBreweries = frc.fetchedObjects! as [Brewery]
                        print("Saved this many breweries in model \(frc.fetchedObjects?.count)")
                        completion(true)
                    } catch {
                        completion(false)
                        fatalError("Fetch failed critcally")
                    }
                }
            }
        }
        // First we see if we already have the styles saved to coredata;
        // if so use the coredata saved styles
        // If we don't have the styles save go query BreweryDB for them.
        //        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        //        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        //        fetchedResultsController = NSFetchedResultsController(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult>, managedObjectContext: (coreDataStack?.backgroundContext)!, sectionNameKeyPath: nil, cacheName: nil)
        //        fetchedResultsController.delegate = self
        //        do {
        //            try fetchedResultsController.performFetch()
        //            print("Fetch breweries complete \(fetchedResultsController.fetchedObjects?.count)")
        //
        //        } catch {
        //            fatalError("Fetch failed critcally")
        //        }
        
        // This was already dont
        // If fetch did not return any items query the REST Api
        //        if fetchedResultsController.fetchedObjects?.count == 0 {
        //            breweryDB.downloadBeerStyles() {
        //                (success) -> Void in
        //                if success {
        //                    // TODO this might not be needed anymore
        //                    //self.styleTable.reloadData()
        //                    // Now that the delegate is properly hooked up
        //                }
        //            }
        //        }
    }
    
    internal func getListOfStyles(completion: @escaping (_ complete: Bool) -> Void ) {
        // This function tries to see if we have results in coredata.
        // If we do, load these results locally and notify the caller to retrieve them
        // If we do not have styles go retrieve them from the REST API and load
        // locally. Finally notify caller to retrieve results.
        var fetchedResultsController : NSFetchedResultsController<Style>?
        func initFetchResultsController(){
            let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
            request.sortDescriptors = [NSSortDescriptor(key: "displayName", ascending: true)]
            fetchedResultsController = NSFetchedResultsController(fetchRequest: request,
                                                                  managedObjectContext: (coreDataStack?.favoritesContext)!,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        }
        initFetchResultsController()
        do {
            // Fetch results and load Model's public variable
            try fetchedResultsController?.performFetch()
            // Load results locally
            //coreDataStack?.stateOfAllContexts()
            listOfStyles = (fetchedResultsController?.fetchedObjects)! as [Style]
        } catch {
            completion(false)
            return
        }
        
        // We have styles already prefetched, notify caller to retrieve data
        guard fetchedResultsController?.fetchedObjects?.count == 0 else {
            completion(true)
            return
        }

        // If fetch did not return any styles from CoreData, query the REST Api
        
        if fetchedResultsController?.fetchedObjects?.count == 0 {
            // Query the REST API
            BreweryDBClient.sharedInstance().downloadBeerStyles() {
                (success) -> Void in
                if success {
                    initFetchResultsController()
                    do {
                        // Fetch results
                        try fetchedResultsController?.performFetch()
                        // Load results locally
                        self.listOfStyles = (fetchedResultsController?.fetchedObjects)! as [Style]
                        // Notify caller they can retrieve data.
                        completion(true)
                    } catch {
                        completion(false)
                        return
                    }
                }
            }
        }
    }
    
}
