//
//  BreweryMapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import MapKit

class BreweryMapStrategy: MapStrategy {

    init(b: Brewery, view: MapViewController, location: CLLocation) {
        super.init()
        targetLocation = location
        breweryLocations.removeAll()
        breweryLocations.append(b)
        mapViewController = view
        sortLocations()
        sendAnnotationsToMap()
    }

}
