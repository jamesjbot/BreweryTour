//
//  Style+CoreDataProperties.swift
//  
//
//  Created by James Jongsurasithiwat on 12/31/16.
//
//

import Foundation
import CoreData


extension Style {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Style> {
        return NSFetchRequest<Style>(entityName: "Style");
    }

    @NSManaged public var displayName: String?
    @NSManaged public var id: String?
    @NSManaged public var brewerywithstyle: NSSet?

}

// MARK: Generated accessors for brewerywithstyle
extension Style {

    @objc(addBrewerywithstyleObject:)
    @NSManaged public func addToBrewerywithstyle(_ value: Brewery)

    @objc(removeBrewerywithstyleObject:)
    @NSManaged public func removeFromBrewerywithstyle(_ value: Brewery)

    @objc(addBrewerywithstyle:)
    @NSManaged public func addToBrewerywithstyle(_ values: NSSet)

    @objc(removeBrewerywithstyle:)
    @NSManaged public func removeFromBrewerywithstyle(_ values: NSSet)

}
