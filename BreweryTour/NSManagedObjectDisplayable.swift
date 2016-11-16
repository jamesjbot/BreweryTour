//
//  NSManagedObjectDisplayable.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData

protocol NSManagedObjectDisplayable {
    func selected(thisItem: NSManagedObject, completion: @escaping (Bool, String?) -> Void)
}
