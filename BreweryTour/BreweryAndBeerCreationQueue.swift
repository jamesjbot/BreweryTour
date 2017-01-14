//
//  BreweryAndBeerCreationQueue.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/28/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

/*
 This program creates Brewery, Beers, and links styles Breweries to styles.
 
 Internal notes.

 */


import Foundation
import UIKit
import CoreData
import Dispatch


internal protocol BreweryAndBeerCreationProtocol {

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
    private let initialMaxSavesPerLoop: Int = 10
    private let initialRepeatInterval: Double = 2

    // Long running loads
    private let longrunningMaxSavesPerLoop: Int = 1000
    private let longRunningRepeatInterval: Double = 60

    private var currentMaxSavesPerLoop: Int = 10
    private var currentRepeatInterval: Double = 2

    private var firstProcessLoopSinceTimerStarted = true
    private var loopCounter: Int = 0


    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container


    // MARK: Variables

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
        (Mediator.sharedInstance() as! BroadcastManagedObjectContextRefresh).registerManagedObjectContextRefresh(self)
    }


    private func switchToInitialRunningDataLoad() {
        currentMaxSavesPerLoop = initialMaxSavesPerLoop
        currentRepeatInterval = initialRepeatInterval
    }


    private func switchToLongRunningDataLoad() {
        currentMaxSavesPerLoop = longrunningMaxSavesPerLoop
        currentRepeatInterval = longRunningRepeatInterval
    }


    private func reinitializeLoadParameter() {
        switchToInitialRunningDataLoad()
        workTimer.invalidate()
        workTimer = nil
    }

    
    // Periodic method to save breweries and beers
    @objc private func processQueue() {
        // This function will save all breweries before saving beers.

        // Currently, the only way to merge Managed Objects with unique constraints is to
        // save them individually, batch does not seem to work.
        // Had to move the merge policy assignment closer to the
        // invocation of save because it was not taking.
        abreweryContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)


        loopCounter += 1
        if loopCounter > 30 {
            switchToLongRunningDataLoad()
        }


        // Save breweries one at time. Batch saving generates conflict errors.
        let dq = DispatchQueue(label: "SerialQueue")
        dq.sync {
            print("Processing breweries creation: we have \(runningBreweryQueue.count) breweries")
            print("Processing beers creation: we have \(runningBeerQueue.count) beers")
            guard !runningBreweryQueue.isEmpty || !runningBeerQueue.isEmpty else {
                // Both queues are empty stop timer
                reinitializeLoadParameter()
                return
            }

            // This adjust the maximum amount of processing per data load
            // Low in the beginning then increasing
            var maxSave: Int!
            maxSave = currentMaxSavesPerLoop
            if runningBreweryQueue.count < maxSave {
                maxSave = runningBreweryQueue.count
            }

            //Processing Breweries
            if !runningBreweryQueue.isEmpty {
                breweryLoop: for _ in 1...maxSave {

                    guard continueProcessingAfterContextRefresh() else {
                        break breweryLoop
                    }

                    let b = runningBreweryQueue.removeFirst()
                    let newBrewery = Brewery(data: b, context: abreweryContext!)

                    // We must save everyupdate individually or Unique constraints on the class will not be preserved
                    if b.styleID != nil {
                        do {
                            // Adds the brewery to the style for easier searching
                            let styleRequest: NSFetchRequest<Style> = Style.fetchRequest()
                            styleRequest.sortDescriptors = []
                            styleRequest.predicate = NSPredicate(format: "id == %@", b.styleID!)
                            var resultStyle = try self.abreweryContext?.fetch(styleRequest)
                            resultStyle?.first?.addToBrewerywithstyle(newBrewery)
                        } catch let error {
                            print(error.localizedDescription)
                        }

                    }

                    // Save brewery and style data.
                    do {
                        try abreweryContext?.save()
                        print("B&BQueue \(#line) saving from processing breweries")
                    } catch let err {
                        print(err.localizedDescription)
                    }

                    if b.imageUrl != nil {
                        // If we have image data download it
                        BreweryDBClient.sharedInstance().downloadImageToCoreData(forType: .Brewery,                                                                               aturl: NSURL(string: b.imageUrl!)!,                                                                             forID: b.id!)
                    }
                }
            }

            // Process beers only if breweries are done.
            guard runningBreweryQueue.isEmpty else {
                // Wait for timer to fire again and process some more beers
                return
            }

            // If runningBeerQueue is empty stop
            guard !runningBeerQueue.isEmpty else {
                return
            }
            // Reset the maximum records to process
            maxSave = currentMaxSavesPerLoop
            if runningBeerQueue.count < maxSave {
                maxSave = runningBeerQueue.count
            }


            // Processing Beers
            beerLoop: for _ in 1...maxSave {

                guard continueProcessingAfterContextRefresh() else {
                    break beerLoop
                }

                // If we select a brewery, then only beers will be generated.
                // Therefore we must attach the styles to the breweries at a beer by beer level.
                var (beer,attempt) = runningBeerQueue.removeFirst()

                let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                request.sortDescriptors = []
                request.predicate = NSPredicate(format: "id == %@", beer.breweryID!)

                // Using peform instead of performandwait to increase performance.
                abreweryContext?.perform {
                    do {
                        let brewers = try self.abreweryContext?.fetch(request)
                        // Request did not find breweries
                        if (brewers?.count)! < 1 {
                            print("This beer can't find brewer \(beer.beerName)")
                            // If we have breweries still running then put beer back
                            if !self.runningBreweryQueue.isEmpty {
                                self.runningBeerQueue.append( (beer,attempt) )
                            } else { // Out of breweries. Try again 8 times then give up
                                if attempt < 8 {
                                    attempt += 1
                                    self.runningBeerQueue.append( (beer,attempt) )
                                }
                            }


                        } else { // Found a Brewery to attach this beer to

                            // Adds the brewery to the style for easier searching
                            let styleRequest: NSFetchRequest<Style> = Style.fetchRequest()
                            styleRequest.sortDescriptors = []
                            styleRequest.predicate = NSPredicate(format: "id == %@", beer.styleID!)
                            var resultStyle = try self.abreweryContext?.fetch(styleRequest)

                            assert(resultStyle?.count == 1)

                            // Checks to see if we already have this brewer attached with style
                            let found = resultStyle?.first?.brewerywithstyle?.contains(brewers?.first as Any)
                            //print("Breweryandbeer \(#line) did we find the brewer in the set \(found)")
                            if !found! {
                                resultStyle?.first?.addToBrewerywithstyle((brewers?.first)!)
                                //print("Added \(brewers?.first?.name) to \(resultStyle?.first?.displayName)")
                                //print("this style now has \(resultStyle?.first?.brewerywithstyle?.count) breweries ")
                            }

                            let createdBeer = Beer(data: beer, context: self.abreweryContext!)
                            createdBeer.brewer = brewers?.first

                            try self.abreweryContext?.save()
                            print("B&BQueue \(#line) saving Style and changes saved")
                            if beer.imageUrl != nil {
                                // If we have image data download it
                                DispatchQueue.global(qos: .utility).async {
                                    BreweryDBClient.sharedInstance().downloadImageToCoreData(forType: .Beer,                                                                               aturl: NSURL(string: beer.imageUrl!)!,                                                                             forID: beer.id!)
                                }

                            }
                        }
                    } catch let error {
                        print(error.localizedDescription)
                        fatalError()
                    }
                }
            } // After beer for loop
        }
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


    fileprivate func startWorkTimer() {
        if workTimer == nil {
            firstProcessLoopSinceTimerStarted = true
            workTimer = Timer.scheduledTimer(timeInterval: currentRepeatInterval,
                                             target: self,
                                             selector: #selector(self.processQueue),
                                             userInfo: nil,
                                             repeats: true)
        }
    }

}


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
        } catch {

        }
        guard brewer?.first == nil else {
            // Skip brewery creation when we already have the brewery
            return
        }
        if let localBrewer = b {
            print("B&BQueue \(#line) brewery queued ")
            startWorkTimer()
            runningBreweryQueue.append(localBrewer)
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
        } catch {

        }
        guard beers?.first == nil else {
            // Skip beer creation when we already have the beer
            return
        }
        if let beer = b {
            print("B&BQueue \(#line) beer queued ")
            startWorkTimer()
            let attempt = 0
            runningBeerQueue.append( (beer,attempt) )
        }
    }
}




