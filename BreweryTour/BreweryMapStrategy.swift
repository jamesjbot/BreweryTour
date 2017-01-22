//
//  BreweryMapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/*
    Subclass to MapStrategy for single brewery
 */

import Foundation
import MapKit

class BreweryMapStrategy: MapStrategy {

    init(b: Brewery, view: MapViewController, location: CLLocation) {
        super.init()
        targetLocation = location
        breweryLocations.removeAll()
        breweryLocations.append(b)
        parentMapViewController = view
        sortLocations()
        sendAnnotationsToMap()
    }

}
