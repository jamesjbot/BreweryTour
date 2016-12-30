//
//  Brewery+CoreDataProperties.swift
//  
//
//  Created by James Jongsurasithiwat on 12/29/16.
//
//

import Foundation
import CoreData


extension Brewery {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Brewery> {
        return NSFetchRequest<Brewery>(entityName: "Brewery");
    }

    @NSManaged public var favorite: Bool
    @NSManaged public var hasOrganic: Bool
    @NSManaged public var id: String?
    @NSManaged public var image: NSData?
    @NSManaged public var latitude: String?
    @NSManaged public var longitude: String?
    @NSManaged public var name: String?
    @NSManaged public var openToThePublic: Bool
    @NSManaged public var url: String?
    @NSManaged public var brewedbeer: NSSet?

}

// MARK: Generated accessors for brewedbeer
extension Brewery {

    @objc(addBrewedbeerObject:)
    @NSManaged public func addToBrewedbeer(_ value: Beer)

    @objc(removeBrewedbeerObject:)
    @NSManaged public func removeFromBrewedbeer(_ value: Beer)

    @objc(addBrewedbeer:)
    @NSManaged public func addToBrewedbeer(_ values: NSSet)

    @objc(removeBrewedbeer:)
    @NSManaged public func removeFromBrewedbeer(_ values: NSSet)

}
