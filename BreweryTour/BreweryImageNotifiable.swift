//
//  BreweryImageNotifiable.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/2/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

protocol BreweryAndBeerImageNotifiable {
    func tellImagesUpdate()
}

protocol BreweryAndBeerImageNotifier {
    func broadcastToBreweryImageObservers()
    func registerAsBrewryImageObserver(t: BreweryImageNotifiable)
}
