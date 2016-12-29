//
//  Brewery+CoreDataClass.swift
//  
//
//  Created by James Jongsurasithiwat on 10/12/16.
//
//

import Foundation
import CoreData


public class Brewery: NSManagedObject {
    convenience init(inName: String,
                     latitude: String?,
                     longitude: String?,
                     url: String?,
                     open: Bool?,
                     id: String?,
                     context: NSManagedObjectContext){
        // Insert new Brewery in database
        let entity = NSEntityDescription.entity(forEntityName: "Brewery", in: context)
        self.init(entity: entity!, insertInto: context)
        self.latitude = latitude ?? ""
        self.longitude = longitude ?? ""
        self.url = url ?? ""
        self.id = id ?? ""
        self.openToThePublic = open ?? false
        self.name = (inName != "" ? inName : "No Brewery Name Listed")
    }

    convenience init(data: BreweryData, context: NSManagedObjectContext) {
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
    
}
