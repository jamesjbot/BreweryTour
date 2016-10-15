//
//  Beer+CoreDataProperties.swift
//  
//
//  Created by James Jongsurasithiwat on 10/15/16.
//
//

import Foundation
import CoreData 

extension Beer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Beer> {
        return NSFetchRequest<Beer>(entityName: "Beer");
    }

    @NSManaged public var availability: String?
    @NSManaged public var beerDescription: String?
    @NSManaged public var beerName: String?
    @NSManaged public var id: String?
    @NSManaged public var style: String?
    @NSManaged public var tastingNotes: String?
    @NSManaged public var favorite: Bool
    @NSManaged public var brewer: Brewery?

}
