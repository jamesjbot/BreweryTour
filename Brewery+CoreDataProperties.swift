//
//  Brewery+CoreDataProperties.swift
//  
//
//  Created by James Jongsurasithiwat on 10/12/16.
//
//

import Foundation
import CoreData


extension Brewery {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Brewery> {
        return NSFetchRequest<Brewery>(entityName: "Brewery");
    }

    @NSManaged public var id: String?
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var name: String?

}
