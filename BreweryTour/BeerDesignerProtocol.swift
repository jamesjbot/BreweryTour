//
//  BeerDesigner.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
/*
 The purpose of the is program is be a central point where the beer information
 is formatted.
 */

import Foundation

protocol BeerDesignerProtocol {
    // Parse beer data and send to creation queue.
    func createBeerObject(beer : [String:AnyObject],
                          brewery: Brewery?,
                          brewerID: String,
                          completion: @escaping (_ out : Beer) -> ())
}


extension BeerDesignerProtocol {
    
    // Parse beer data and send to creation queue.
    func createBeerObject(beer : [String:AnyObject],
                                  brewery: Brewery? = nil,
                                  brewerID: String,
                                  completion: @escaping (_ out : Beer) -> ()) {

        let beer = BeerData(inputAvailability: beer["available"]?["description"] as? String ?? "No Information Provided",
                            inDescription: beer["description"] as? String ?? "No Information Provided",
                            inName: beer["name"] as? String ?? "",
                            inBrewerId: brewerID,
                            inId: beer["id"] as! String,
                            inImageURL: beer["labels"]?["medium"] as? String ?? "",
                            inIsOrganic: beer["isOrganic"] as? String == "Y" ? true : false,
                            inStyle: (beer["styleId"] as! NSNumber).description,
                            inAbv: beer["abv"] as? String ?? "N/A",
                            inIbu: beer["ibu"] as? String ?? "N/A")

        BreweryAndBeerCreationQueue.sharedInstance().queueBeer(beer)
    }
}


class BeerDesigner: BeerDesignerProtocol {

    private init() {}
    internal class func sharedInstanct() -> BeerDesignerProtocol {
        struct Singleton {
            static var sharedInstance = BeerDesigner()
        }
        return Singleton.sharedInstance
    }
}
