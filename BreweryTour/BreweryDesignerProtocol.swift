//
//  BreweryDesigner.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
/*
 The purpose of the is program is be a central point where brewery information
 is formatted.
 */

import Foundation

protocol BreweryDesignerProtocol {
    // Parse brewery data and send to creation queue.
    func createBreweryObject(breweryDict: [String:AnyObject],
                             locationDict locDict: [String:AnyObject],
                             brewersID: String,
                             style: String?,
                             completion: @escaping (_ out : Brewery) -> () )
}


extension BreweryDesignerProtocol {

    func createBreweryObject(breweryDict: [String:AnyObject],
                             locationDict locDict: [String:AnyObject],
                             brewersID: String,
                             style: String?,
                             completion: @escaping (_ out : Brewery) -> () ) {
        guard let breweryName = breweryDict["name"] as? String,
            let latitude = locDict["latitude"]?.description,
            let longitude = locDict["longitude"]?.description else {
            return
        }
        let breweryData = BreweryData(
            inName: breweryName,
            inLatitude: latitude,
            inLongitude: longitude,
            inUrl: (locDict["website"] as? String ?? ""),
            open: (locDict["openToPublic"] as? String == "Y") ? true : false,
            inId: brewersID,
            inImageUrl: breweryDict["images"]?["icon"] as? String ?? "",
            inStyleID: style)

        BreweryAndBeerCreationQueue.sharedInstance().queueBrewery(breweryData)
    }
}


class BreweryDesigner: BreweryDesignerProtocol {

    private init() {}
    internal class func sharedInstance() -> BreweryDesignerProtocol {
        struct Singleton {
            static var sharedInstance = BreweryDesigner()
        }
        return Singleton.sharedInstance
    }
}
