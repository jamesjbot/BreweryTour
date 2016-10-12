//
//  Style+CoreDataProperties.swift
//  
//
//  Created by James Jongsurasithiwat on 10/12/16.
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

}
