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
    var creationQueue: BreweryAndBeerCreationProtocol? { get set }
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

        guard let beerId = beer["id"] as? String,
            let styleId = (beer["styleId"] as? NSNumber)?.description else {
            return
        }

        let beerForQueue = BeerData(inputAvailability: beer["available"]?["description"] as? String ?? "No Information Provided",
                            inDescription: beer["description"] as? String ?? "No Information Provided",
                            inName: beer["name"] as? String ?? "",
                            inBrewerId: brewerID,
                            inId: beerId,
                            inImageURL: beer["labels"]?["medium"] as? String ?? "",
                            inIsOrganic: beer["isOrganic"] as? String == "Y" ? true : false,
                            inStyle: styleId,
                            inAbv: beer["abv"] as? String ?? "N/A",
                            inIbu: beer["ibu"] as? String ?? "N/A")
        // FIXME
        creationQueue!.queueBeer(beerForQueue)
    }
}


class BeerDesigner: BeerDesignerProtocol {
    var creationQueue: BreweryAndBeerCreationProtocol?
    init(with creationQueue: BreweryAndBeerCreationProtocol ) {
        self.creationQueue = creationQueue
    }
//    private init() {}
//    internal class func sharedInstance() -> BeerDesignerProtocol {
//        struct Singleton {
//            static var sharedInstance = BeerDesigner()
//        }
//        return Singleton.sharedInstance
//    }
}
