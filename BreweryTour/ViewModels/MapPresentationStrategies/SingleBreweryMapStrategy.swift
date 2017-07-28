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

class SingleBreweryMapStrategy: MapStrategy {

    init(b singleBrewery: Brewery, view: MapViewController, location: CLLocation) {
        super.init()
        targetLocation = location
        breweryLocations.removeAll()
        breweryLocations.append(singleBrewery)
        parentMapViewController = view
        SwiftyBeaver.info("SingleBreweryMapStrategy callign sortLocation in initialization logic.")
        sortLocations()
        sendAnnotationsToMap()
    }

}
