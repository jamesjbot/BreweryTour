//
//  Style+CoreDataClass.swift
//
//
//  Created by James Jongsurasithiwat on 10/12/16.
//
//

import Foundation
import CoreData


public class Style: NSManagedObject {
    convenience init(id: String, name: String, context : NSManagedObjectContext){
        let entityDescription = NSEntityDescription.entity(forEntityName: "Style", in: context)
        self.init(entity: entityDescription!, insertInto: context)
        self.displayName = name
        self.id = id
    }
}
