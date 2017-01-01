//
//  ContextRefreshProtocols.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

// This protocol allows the class to be told when to refrehsAllObjects on its
// Managed context (this likely goes on view models or views themselves)
protocol UpdateManagedObjectContext {
    func contextsRefreshAllObjects()
}


// This protocl belongs to class's that wants to
// aggregate observer's and notifies said observers.
protocol NotifyFRCToUpdate {
    func registerManagedObjectContextRefresh(_ a: UpdateManagedObjectContext)
    func allBeersAndBreweriesDeleted()
}
