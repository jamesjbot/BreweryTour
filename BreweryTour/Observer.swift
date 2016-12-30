//
//  Observer.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/21/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

protocol Observer {
    func sendNotify(from: AnyObject, withMsg msg: String )
}
