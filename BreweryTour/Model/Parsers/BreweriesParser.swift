//
//  BreweriesParser.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
import CoreData
import UIKit

class BreweriesParser: ParserProtocol {

    var breweryDesigner: BreweryDesignerProtocol

    init(with breweryDesigner: BreweryDesignerProtocol) {
        self.breweryDesigner = breweryDesigner
    }

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
            guard let locationInfo = breweryDict["locations"] as? NSArray,
                let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                let openToPublic = locDic["openToPublic"],
                openToPublic as! String == "Y",
                locDic["longitude"] != nil,
                locDic["latitude"] != nil,
                breweryDict["name"] != nil // Without name can't store.
                else {
                    continue breweryLoop
            }

            // Make one brewers id
            guard let brewersID = (locDic["id"]?.description) else {
                continue breweryLoop
            }

            breweryDesigner.createBreweryObject(breweryDict: breweryDict as Dictionary,
                                                locationDict: locDic,
                                                brewersID: brewersID,
                                                style: nil) { // There is no style to pull in when looking for breweries only.
                                                    (thisbrewery) -> Void in
            }
        } // end of breweryLoop
        completion?(true, "Success")
    }
}
