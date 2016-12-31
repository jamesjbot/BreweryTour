//
//  BreweryWithStyleQuery.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/31/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class BreweryWithStyleQuery: NSObject {

    override init() {
        super.init()
    }

    internal func getListOfBreweries(withStyle: Style) {
        // Fetch all the beers with style currently available
        // Go thru each beer if the brewery is on the map skip it
        // If not put the beer's brewery in breweriesToBeProcessed.

        // Fetch all the beers with style
        let request : NSFetchRequest<Beer> = Beer.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "styleID = %@", withStyle.id!)
        // A static view of current breweries with styles
        var results : [Beer]!
        beerFRC = NSFetchedResultsController(fetchRequest: request ,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        // Sign up for updates
        beerFRC?.delegate = self

        // Prime the fetched results controller
        do {
            _ = try beerFRC?.performFetch()
            results = (beerFRC?.fetchedObjects!)! as [Beer]
        } catch {
            self.displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again.")
            return
        }
        // Now that we have Beers with that style, what breweries are associated
        // with these beers
        var uniqueBreweries = [Brewery]() // Array to hold breweries

        // Remove duplicate breweries
        for beer in results {
            if beer.brewer != nil {
                // Only unique breweries are processed
                if !uniqueBreweries.contains(beer.brewer!) {
                    uniqueBreweries.append(beer.brewer!)
                    // Hand breweries off to be processed.
                    breweriesToBeProcessed.append(beer.brewer!)
                }
            }
        }

    }

}


