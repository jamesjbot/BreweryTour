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
        self.name = name
        self.beerDescription = beerDescription
        self.availability = availability
        //self.style = style
        self.id = id
    }
}
