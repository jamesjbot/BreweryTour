//
//  Beer+CoreDataClass.swift
//  
//
//  Created by James Jongsurasithiwat on 10/12/16.
//
//

import Foundation
import CoreData

public class Beer: NSManagedObject {
    convenience init(id: String, name: String , beerDescription: String, availability: String, context : NSManagedObjectContext){
        let entityDescription = NSEntityDescription.entity(forEntityName: "Beer", in: context)
        self.init(entity: entityDescription!, insertInto: context)
        self.beerName = name
        self.beerDescription = beerDescription
        self.availability = availability
        //self.style = style
        self.id = id
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
        self.favorite = favorite!
        self.id = id
        self.image = image
        self.imageUrl = imageURL
        self.tastingNotes = tasting
        self.style = style
    }
    

}
