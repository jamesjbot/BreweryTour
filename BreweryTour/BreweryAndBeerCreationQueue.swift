//
//  BreweryAndBeerCreationQueue.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/28/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

/*
    This program creates Brewery, Beers, and links styles Breweries to styles.
 */


import Foundation
import UIKit
import CoreData
import Dispatch



protocol WorkSubject {
    func registerMediatorObserver(m: MediatorBusyObserver)
}

extension BreweryAndBeerCreationQueue: WorkSubject {
    func registerMediatorObserver(m: MediatorBusyObserver) {
        mediatorObserver = m
    }
}

protocol BreweryAndBeerCreationProtocol {

    func isBreweryAndBeerCreationRunning() -> Bool
    func queueBrewery(_ b: BreweryData?)
    func queueBeer(_ b: BeerData?)
}


extension BreweryAndBeerCreationQueue: ReceiveBroadcastManagedObjectContextRefresh {
    func contextsRefreshAllObjects() {
        abandonProcessingQueue = true
        abreweryContext?.refreshAllObjects()
    }
}


class BreweryAndBeerCreationQueue: NSObject {

    fileprivate var abandonProcessingQueue: Bool = false

    // MARK: Constants

    // Initial responsive load
    private let initialMaxSavesPerLoop: Int = 3
    private let initialRepeatInterval: Double = 3

    // Long running loads
    // System fastest processes is 1.2 records / second
    private let longrunningMaxSavesPerLoop: Int = 250
    private let longRunningRepeatInterval: Double = 45

    private let maximumSmallRuns = 30

    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container


    // MARK: Variables
    fileprivate var mediatorObserver: MediatorBusyObserver?

    private var currentMaxSavesPerLoop: Int = 0
    private var currentRepeatInterval: Double = 0

    private var loopCounter: Int = 0

    private var workTimer: Timer!

    private var breweryQueue: DispatchQueue = DispatchQueue.global(qos: .background)

    fileprivate var runningBreweryQueue = [BreweryData]()
    fileprivate var runningBeerQueue = [(BeerData,Int)]()

    fileprivate var abreweryContext: NSManagedObjectContext? {
        didSet {
            abreweryContext?.automaticallyMergesChangesFromParent = true
        }
    }


    // MARK: Functions

    internal class func sharedInstance() -> BreweryAndBeerCreationProtocol {
        struct Singleton {
            static var sharedInstance = BreweryAndBeerCreationQueue()
        }
        return Singleton.sharedInstance
    }


    private override init() {
        super.init()
        workTimer = Timer.scheduledTimer(timeInterval: currentRepeatInterval,
                                         target: self,
                                         selector: #selector(self.processQueue),
                                         userInfo: nil,
                                         repeats: true)
        abreweryContext = container?.newBackgroundContext()
        (Mediator.sharedInstance() as BroadcastManagedObjectContextRefresh).registerManagedObjectContextRefresh(self)
        mediatorObserver = Mediator.sharedInstance() as MediatorBusyObserver
        switchToInitialRunningDataLoad()
    }


    private func continueProcessingAfterContextRefresh() -> Bool {
        // We've been told to abandon Processing because of a core data refresh.
        if abandonProcessingQueue {
            runningBeerQueue.removeAll()
            runningBreweryQueue.removeAll()
            abandonProcessingQueue = false
            return false
        }
        return true
    }



    private func reinsertBeer(_ beer: BeerData, _ inAttempt: Int) {
        // If we have breweries still running then put beer back
        var attempt = inAttempt
        if !runningBreweryQueue.isEmpty {
            runningBeerQueue.append( (beer,attempt) )
        } else { // Out of breweries. Try again 3 times then give up
            if attempt < 3 {
                attempt += 1
                self.runningBeerQueue.append( (beer,attempt) )
            }
        }
    }


    private func reinitializeLoadParameter() {
        switchToInitialRunningDataLoad()
        stopWork()
    }


    fileprivate func startWorkTimer() {
        if workTimer == nil {
            workTimer = Timer.scheduledTimer(timeInterval: currentRepeatInterval,
                                             target: self,
                                             selector: #selector(self.processQueue),
                                             userInfo: nil,
                                             repeats: true)
        }
        mediatorObserver?.notifyStartingWork()
    }

    
    private func stopWork() {
        workTimer.invalidate()
        workTimer = nil
        mediatorObserver?.notifyStoppingWork()
    }


    private func switchToInitialRunningDataLoad() {
        currentMaxSavesPerLoop = initialMaxSavesPerLoop
        currentRepeatInterval = initialRepeatInterval
    }


    private func switchToLongRunningDataLoad() {
        currentMaxSavesPerLoop = longrunningMaxSavesPerLoop
        currentRepeatInterval = longRunningRepeatInterval
        loopCounter = 0
    }


    
    // Periodic method to save breweries and beers
    @objc private func processQueue() {
        // This function will save all breweries before saving beers.

        abreweryContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)

        abreweryContext?.performAndWait {

            self.loopCounter += 1
            if self.loopCounter > self.maximumSmallRuns {
               self.switchToLongRunningDataLoad()
            }

            // Save breweries one at time. Batch saving generates conflict errors.
            let dq = DispatchQueue(label: "SerialQueue")
            dq.sync {
                print("Processing breweries creation: we have \(self.runningBreweryQueue.count) breweries")
                print("Processing beers creation: we have \(self.runningBeerQueue.count) beers")
                guard !self.runningBreweryQueue.isEmpty || !self.runningBeerQueue.isEmpty else {
                    // Both queues are empty stop timer
                    self.self.reinitializeLoadParameter()
                    return
                }

                // This adjusts the maximum amount of processing per data load
                // Low in the beginning then increasing
                var maxSave: Int!
                maxSave = self.decideOnMaximumRecordsPerLoop(queueCount: self.runningBreweryQueue.count)

                // Processing Breweries
                if !self.runningBreweryQueue.isEmpty { // Should we skip brewery processing
                    self.processBreweryLoop(maxSave)
                }

                // Begin to process beers only if breweries are done.
                guard self.runningBreweryQueue.isEmpty else {
                    // Else Wait for timer to fire again and process some more
                    // Breweries
                    return
                }

                // Reset the maximum records to process
                maxSave = self.decideOnMaximumRecordsPerLoop(queueCount: self.runningBeerQueue.count)
                
                // Process Beers
                if !self.runningBeerQueue.isEmpty { // We skip beer processing when
                    self.processBeerLoop(maxSave)
                }
            }
        }
    }


    private func decideOnDownloadingImage(fromURL: String?, forType: ImageDownloadType, forID: String) {
        if let url = fromURL {
            DispatchQueue.global(qos: .utility).async {
                BreweryDBClient.sharedInstance().downloadImageToCoreData(forType: forType,
                                                                         aturl: NSURL(string: url)!,
                                                                         forID: forID)
            }
        }
    }


    private func processBeerLoop(_ maxSave: Int) {
        // Processing Beers
        abreweryContext?.performAndWait {
            autoreleasepool {

                beerLoop: for _ in 1...maxSave {

                    guard self.continueProcessingAfterContextRefresh() else {
                        break beerLoop
                    }

                    // If we select a brewery, then only beers will be generated.
                    // Therefore we must attach the styles to the breweries at a beer by beer level.
                    let (beer,attempt) = self.runningBeerQueue.removeFirst()

                    let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                    request.sortDescriptors = []
                    request.predicate = NSPredicate(format: "id == %@", beer.breweryID!)

                    do {
                        let brewers = try self.abreweryContext?.fetch(request)

                        // Request did not find breweries
                        guard brewers?.count == 1 else {
                            self.reinsertBeer(beer,attempt)
                            continue
                        }

                        if let styleID = beer.styleID {
                            self.add(brewery: (brewers?.first)!, toStyleID: styleID)
                        }

                        let createdBeer = Beer(data: beer, context: self.abreweryContext!)
                        createdBeer.brewer = brewers?.first

                        self.decideOnDownloadingImage(fromURL: beer.imageUrl, forType: .Beer, forID: beer.id!)

                    } catch let error {
                        NSLog("There was and error saving brewery to style\(error.localizedDescription)")
                        fatalError()
                    }
                }
            }
            // Help slow saving and memory leak.
            do {
                self.abreweryContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
                if (self.abreweryContext!.hasChanges) {
                    try self.abreweryContext?.save()
                }
                // Reset to help running out of memory
                self.abreweryContext?.reset()
            } catch let error {
                NSLog("There was and error saving brewery to style\(error.localizedDescription)")
            }
        }
    }


    private func processBreweryLoop(_ maxSave: Int) {
        abreweryContext?.performAndWait {

            autoreleasepool {
                breweryLoop: for _ in 1...maxSave {
                    guard self.continueProcessingAfterContextRefresh() else {
                        break breweryLoop
                    }

                    let b = self.runningBreweryQueue.removeFirst()
                    let newBrewery = Brewery(data: b, context: self.abreweryContext!)

                    if let styleID = b.styleID {
                        self.add(brewery: newBrewery, toStyleID: styleID)
                    }

                    self.decideOnDownloadingImage(fromURL: b.imageUrl, forType: .Brewery, forID: b.id!)
                }
            }
            // Save brewery and style data.
            do {
                self.abreweryContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
                try self.abreweryContext?.save()
            } catch let error {
                NSLog("There was and error saving brewery \(error.localizedDescription)")
            }
        }
    }


    private func add(brewery newBrewery: Brewery, toStyleID: String) {
        do {
            // Adds the brewery to the style for easier searching
            let styleRequest: NSFetchRequest<Style> = Style.fetchRequest()
            styleRequest.sortDescriptors = []
            styleRequest.predicate = NSPredicate(format: "id == %@", toStyleID)
            let resultStyle = try self.abreweryContext?.fetch(styleRequest)
            resultStyle?.first?.addToBrewerywithstyle(newBrewery)
        } catch let error {
            NSLog("There was and error saving brewery to style\(error.localizedDescription)")
        }
    }


    private func decideOnMaximumRecordsPerLoop(queueCount: Int) -> Int {
        var maxSave = currentMaxSavesPerLoop
        if queueCount < maxSave {
            maxSave = queueCount
        }
        return maxSave
    }
}



//  MARK: - BreweryAndBeerCreationProtocol

extension BreweryAndBeerCreationQueue: BreweryAndBeerCreationProtocol {

    internal func isBreweryAndBeerCreationRunning() -> Bool {
        if runningBreweryQueue.isEmpty && runningBeerQueue.isEmpty {
            return false
        }
        return true
    }

    // Queues up breweries to be saved
    internal func queueBrewery(_ b: BreweryData?) {
        // Check to see if brewery exists
        let context = container?.newBackgroundContext()
        let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id== %@", (b?.id)!)
        var brewer: [Brewery]?
        do {
            brewer = try context?.fetch(request)
        } catch let error{
            NSLog("Error finding a brewery because \(error.localizedDescription)")
        }
        guard brewer?.first == nil else {
            // Skip brewery creation when we already have the brewery
            return
        }
        if let localBrewer = b {
            runningBreweryQueue.append(localBrewer)
            startWorkTimer()
        }
    }


    // Queues up beers to be saved
    internal func queueBeer(_ b: BeerData?) {
        // Check to see if beer exists
        let context = container?.newBackgroundContext()
        let request: NSFetchRequest<Beer> = Beer.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id == %@", (b?.id)!)
        var beers: [Beer]?
        do {
            beers = try context?.fetch(request)
        } catch let error{
            NSLog("Error finding a Beer because \(error.localizedDescription)")
        }
        guard beers?.first == nil else {
            // Skip beer creation when we already have the beer
            return
        }
        if let beer = b {
            let attempt = 0
            runningBeerQueue.append( (beer,attempt) )
            startWorkTimer()
        }
    }
}




