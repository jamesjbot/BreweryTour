//
//  BreweryAnnotation.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 5/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import MapKit

class BreweryAnnotation: NSObject, MKAnnotation {

    var coordinate: CLLocationCoordinate2D

    var brewery: Brewery?

    var breweryName: String?
    var breweryWebsite: String?
    var favorite: Bool?

    init(brewery input: Brewery) {
        brewery = input
        breweryName = brewery?.name
        breweryWebsite = brewery?.url
        coordinate = input.getLocation()!
        favorite = brewery?.favorite
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        if let input = object as? Brewery {
            return breweryName == input.name
        }
        return false
    }
}
