//
//  Beer.swift
//
//
//  Created by James Jongsurasithiwat on 08/02/17.
//
//

import Foundation
import CoreData
import SwiftyBeaver

public class Beer: NSManagedObject {

    convenience init(id: String,
                     name: String,
                     beerDescription: String,
                     availability: String,
                     context : NSManagedObjectContext){

        let entityDescription = NSEntityDescription.entity(forEntityName: "Beer", in: context)

        self.init(entity: entityDescription!, insertInto: context)

        self.beerName = name
        self.beerDescription = beerDescription
        self.availability = availability
        self.id = id
    }


    convenience init(data: BeerData,
                     context: NSManagedObjectContext) throws {

        let entityDescription = NSEntityDescription.entity(forEntityName: "Beer", in: context)!

        self.init(entity: entityDescription,
                  insertInto: context)

        availability = data.availability
        beerDescription = data.beerDescription
        beerName = data.beerName
        breweryID = data.breweryID
        id = data.id
        imageUrl = data.imageUrl
        isOrganic = data.isOrganic
        styleID = data.styleID
        abv = data.abv
        ibu = data.ibu
    }

    convenience init(name : String?,
                     brewer : Brewery?,
                     availability : String?,
                     image : NSData?,
                     imageURL : String?,
                     favorite : Bool?,
                     description : String?,
                     id : String,
                     tasting : String?,
                     style : String?,
                     context: NSManagedObjectContext){
        let entityDescription = NSEntityDescription.entity(forEntityName: "Beer", in: context)

        self.init(entity: entityDescription!, insertInto: context)

        self.beerName = name
        self.beerDescription = description
        self.availability = availability
        self.brewer = brewer
        self.favorite = favorite ?? false
        self.id = id
        self.image = image
        self.imageUrl = imageURL
        self.tastingNotes = tasting
        self.styleID = style
        self.breweryID = brewer?.id
    }
    
    
}
