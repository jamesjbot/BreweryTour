//
//  Beer+CoreDataProperties.swift
//  
//
//  Created by James Jongsurasithiwat on 10/31/16.
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
    @NSManaged public var breweryID: String?
    @NSManaged public var favorite: Bool
    @NSManaged public var id: String?
    @NSManaged public var image: NSData?
    @NSManaged public var imageUrl: String?
    @NSManaged public var isOrganic: Bool
    @NSManaged public var styleID: String?
    @NSManaged public var tastingNotes: String?
    @NSManaged public var abv: String?
    @NSManaged public var ibu: String?
    @NSManaged public var brewer: Brewery?

}
