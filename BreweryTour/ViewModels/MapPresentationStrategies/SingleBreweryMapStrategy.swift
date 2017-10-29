//
//  SingleBreweryMapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/*
    Concrete Subclass to MapStrategy for single brewery
 */

import Foundation
import MapKit
import SwiftyBeaver

final class SingleBreweryMapStrategy: MappableStrategy {

    var parentMapViewController: MapAnnotationReceiver? = nil
    var targetLocation: CLLocation? = nil
    private var onlyBrewery: Brewery?

    convenience init(b singleBrewery: Brewery,
                     view: MapAnnotationReceiver,
                     location: CLLocation) {

        self.init(view: view)
        //SwiftyBeaver.info("SingelBreweryMapStrategy created")
        
        onlyBrewery = singleBrewery
        targetLocation = location
        parentMapViewController = view
        send(annotations: convertBreweryToAnnotation(breweries: [singleBrewery]), to: parentMapViewController!)
    }


    func endSearch() -> (()->())?{

        // Doesn't need to do anything except conform to protocol
        return nil
    }


    func getBreweries() -> [Brewery] {

        guard let onlyBrewery = onlyBrewery else {
            //SwiftyBeaver.error("How was a SingleBreweryMapStrategy populated without a brewery? \(String(describing: self.onlyBrewery))")
            return []
        }
        return [onlyBrewery]
    }


}
