//
//  BeersByBreweryIDParser.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

class BeersByBreweryIDParser: ParserProtocol {

    func parse(response : NSDictionary,
               querySpecificID : String?,
               completion: (( (_ success :  Bool, _ msg: String?) -> Void )?) ) {
        // Since were are querying by brewery ID we can be guaranteed that
        // the brewery exists, therefore we can use the querySpecificID!.
        guard let beerArray = response["data"] as? [[String:AnyObject]] else {
            // Failed to extract data
            completion?(false, "There are no beers listed for this brewer.")
            return
        }
        createBeerLoop: for beer in beerArray {

            // Assure that we have a beer with style id
            guard beer["styleId"] != nil else {
                continue createBeerLoop
            }

            if let queryID = querySpecificID {
                BeerDesigner.sharedInstance().createBeerObject(beer: beer, brewerID: queryID) {
                    (Beer) -> Void in
                }
            }

        }

    }

}
