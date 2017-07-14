//
//  BreweriesByStateParser.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/25/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
//
import CoreData
import UIKit

class BreweriesByStateParser: ParserProtocol {

    func parse(response : NSDictionary,
               querySpecificID : String?,
               completion: (( (_ success :  Bool, _ msg: String?) -> Void )?) ) {

        // If there are no pages means there is nothing to process.
        guard (response["numberOfPages"] as? Int) != nil else {
            completion?(false, "No results returned")
            return
        }

        // Unable to parse Brewery Failed to extract data
        guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
            completion?(false, "Network error please try again")
            return
        }

        breweryLoop: for breweryDict in breweryArray {

            // Can't build a brewery location if no location exist skip brewery
            guard let openToPublic = breweryDict["openToPublic"],
                openToPublic as! String == "Y",
                breweryDict["longitude"] != nil,
                breweryDict["latitude"] != nil,
                breweryDict["brewery"]?["name"] != nil // Can't store without name
                else {
                    continue breweryLoop
            }

            // Make one brewers id
            guard let brewersID = (breweryDict["breweryId"]?.description) else {
                continue breweryLoop
            }

            BreweryDesigner.sharedInstance().createBreweryObject(
                breweryDict: breweryDict["brewery"] as! Dictionary,
                locationDict: breweryDict,
                brewersID: brewersID,
                style: nil) { // There is no style to pull in when looking for breweries only.
                (thisbrewery) -> Void in
            }
        } // end of breweryLoop
        completion?(true, "Success")
    }
}
