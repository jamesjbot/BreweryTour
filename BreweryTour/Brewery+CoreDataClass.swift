//
//  Brewery+CoreDataClass.swift
//  
//
//  Created by James Jongsurasithiwat on 10/12/16.
//
//

import Foundation
import CoreData


public class Brewery: NSManagedObject {
    convenience init(name: String,
                     latitude: String?,
                     longitude: String?,
                     url: String?,
                     open: Bool?,
                     id: String?,
                     context: NSManagedObjectContext){
        let entity = NSEntityDescription.entity(forEntityName: "Brewery", in: context)
        self.init(entity: entity!, insertInto: context)
        self.latitude = latitude ?? ""
        self.longitude = longitude ?? ""
        self.url = url ?? ""
        self.id = id ?? ""
        self.openToThePublic = open ?? false
    }
}
