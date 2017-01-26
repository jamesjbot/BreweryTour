//
//  NSManagedObjectDisplayable.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/20/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData

// Input to Mediator Protocol managed by the CategorySelectionScreen. Selected Object
protocol MediatorBroadcastSetSelected {
    func select(thisItem: NSManagedObject?,state: String?, completion: @escaping (Bool, String?) -> Void)
    func registerForObjectUpdate(observer: ReceiveBroadcastSetSelected)

}

// Output commands from Mediator to NSManagedObject observers
// This is the protocol, observers must implement
protocol ReceiveBroadcastSetSelected {
    func updateObserversSelected(item: NSManagedObject)
}
