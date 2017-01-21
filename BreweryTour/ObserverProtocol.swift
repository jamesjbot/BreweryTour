//
//  Observer.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/21/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

struct Message {
    static let Reload = "reload data"
    static let Retry = "Failed to download initial styles\ncheck network connection and try again."
}

protocol Observer {

    func sendNotify(from: AnyObject, withMsg msg: String )
}
