//
//  MapViewModel.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/26/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData

class MapViewModel : Observer{
    
    var med : Mediator!
    
    var selectedObject : NSManagedObject = NSManagedObject()
    
    init () {
        med = Mediator.sharedInstance()
    }
    
    
    func sendNotify(s: String) {
        print("Received string in return")
    }
}
