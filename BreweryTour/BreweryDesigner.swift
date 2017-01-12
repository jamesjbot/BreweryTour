//
//  BreweryDesigner.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

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
        let breweryData = BreweryData(
            inName: breweryDict["name"] as! String,
            inLatitude: (locDict["latitude"]?.description)!,
            inLongitude: (locDict["longitude"]?.description)!,
            inUrl: (locDict["website"] as! String? ?? ""),
            open: (locDict["openToPublic"] as! String == "Y") ? true : false,
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
