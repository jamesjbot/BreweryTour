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
import Bond

final class SingleBreweryMapStrategy: NSObject, MappableStrategy {

    var annotations: MutableObservableArray<MKAnnotation>

    var parentMapViewController: MapAnnotationReceiver? = nil
    var targetLocation: CLLocation? = nil
    private var onlyBrewery: Brewery?

    override init() {
        annotations = MutableObservableArray<MKAnnotation>()
        super.init()
    }

    convenience init(b singleBrewery: Brewery,
                     view: MapAnnotationReceiver,
                     location: CLLocation) {

        self.init(view: view)
        log.info("SingleBreweryMapStrategy created")
        
        onlyBrewery = singleBrewery
        targetLocation = location
        parentMapViewController = view
        annotations.replace(with: convertBreweryToAnnotation(breweries: [singleBrewery]))
    }


    func endSearch() -> (()->())?{

        // Doesn't need to do anything except conform to protocol
        return nil
    }


    func getBreweries() -> [Brewery] {

        guard let onlyBrewery = onlyBrewery else {

            return []
        }
        return [onlyBrewery]
    }


}
