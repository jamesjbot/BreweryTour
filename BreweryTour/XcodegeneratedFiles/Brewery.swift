//
//  Brewery.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 8/2/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation

public class Brewery: NSManagedObject {

    convenience init(inName: String,
                     latitude: String?,
                     longitude: String?,
                     url: String?,
                     open: Bool?,
                     id: String?,
                     context: NSManagedObjectContext){
        // Insert new Brewery in database
        self.init(context: context)
        self.latitude = latitude ?? ""
        self.longitude = longitude ?? ""
        self.url = url ?? ""
        self.id = id ?? ""
        self.openToThePublic = open ?? false
        self.name = (inName != "" ? inName : "No Brewery Name Listed")
    }

    convenience init(with data: BreweryData, context: NSManagedObjectContext) {
        self.init(entity: Brewery.entity(), insertInto: context)
        self.latitude = data.latitude
        self.longitude = data.longitude
        self.url = data.url
        self.id = data.id
        self.openToThePublic = data.openToThePublic
        self.name = data.name
    }

    convenience init(inBrewery: Brewery,
                     context: NSManagedObjectContext){
        // Insert new Brewery in database
        let entity = NSEntityDescription.entity(forEntityName: "Brewery",
                                                in: context)
        self.init(entity: entity!, insertInto: context)
        self.latitude = inBrewery.latitude
        self.longitude = inBrewery.longitude
        self.url = inBrewery.url
        self.id = inBrewery.id
        self.openToThePublic = inBrewery.openToThePublic
        self.name = inBrewery.name != "" ? inBrewery.name : "No Brewery Name Listed"
        self.image = inBrewery.image
    }

    func getLocation() -> CLLocationCoordinate2D? {
        let lat = CLLocationDegrees(floatLiteral: Double(latitude ?? "0.0")!)
        let long = CLLocationDegrees(floatLiteral: Double(longitude ?? "0.0")!)
        return CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
}
