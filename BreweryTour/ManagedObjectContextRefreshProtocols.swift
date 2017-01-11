//
//  ManagedObjectContextRefreshProtocols.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

// This protocol allows the class to be told when to refrehsAllObjects on its
// Managed context (this likely goes on view models or views themselves)
protocol ReceiveBroadcastManagedObjectContextRefresh {
    func contextsRefreshAllObjects()
}


// This protocl belongs to class's that wants to
// aggregate observer's and notifies all observers.
protocol BroadcastManagedObjectContextRefresh {
    func registerManagedObjectContextRefresh(_ a: ReceiveBroadcastManagedObjectContextRefresh)
    func allBeersAndBreweriesDeleted()
}
