//
//  BusyObservers.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/18/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

protocol BusyObserver {
    func registerAsBusyObserverWithMediator()
    func startAnimating()
    func stopAnimating()
}


protocol MediatorBusyObserver {
    func registerForBusyIndicator(observer: BusyObserver)
    func notifyStartingWork()
    func notifyStoppingWork()
    func isSystemBusy() -> Bool
}
