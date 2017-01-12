//
//  BeersFollowedByBreweriesParser.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

class BeersFollowedByBreweriesParser: ParserProtocol {

    func parse(response : NSDictionary,
               querySpecificID : String?,
               completion: (( (_ success :  Bool, _ msg: String?) -> Void )?) ) {

        guard let beerArray = response["data"] as? [[String:AnyObject]] else {// No beer data was returned, exit
            completion!(false, "Failed Request No data was returned")
            return
        }

        createBeerLoop: for beer in beerArray {

            guard let breweriesArray = beer["breweries"], // Must have brewery information
                beer["styleId"] != nil // Must have a style id
                else {
                    continue createBeerLoop
            }

            breweryLoop: for brewery in (breweriesArray as! Array<AnyObject>) {

                guard let breweryDict = brewery as? [String : AnyObject],
                    let locationInfo = breweryDict["locations"] as? NSArray,
                    let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary, // Must have information
                    locDic["openToPublic"] as! String == "Y", // Must be open to the public
                    locDic["longitude"] != nil, // Must have a location
                    locDic["latitude"] != nil,
                    locDic["id"]?.description != nil  // Must have an id to link
                    else {
                        continue createBeerLoop
                }

                guard breweryDict["name"] != nil else { // Sometimes the breweries have no name, making it useless
                    continue breweryLoop
                }

                let brewersID = (locDic["id"]?.description)! // Make one brewersID for both beer and brewery

                // Send to brewery creation process
                BreweryDesigner.sharedInstance().createBreweryObject(breweryDict: breweryDict,
                                         locationDict: locDic,
                                         brewersID: brewersID,
                                         style: (beer["styleId"] as! NSNumber).description) {
                                            (Brewery) -> Void in
                }
                
                // Send to beer creation process
                BeerDesigner.sharedInstanct().createBeerObject(beer: beer, brewerID: brewersID) {
                    (Beer) -> Void in
                }
                
                // Process only one brewery per beer
                break breweryLoop
                
            } //  end of brewery loop
        } // end of beer loop
    }
}
