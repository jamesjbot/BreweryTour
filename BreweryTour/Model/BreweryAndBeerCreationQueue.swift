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
import SwiftyBeaver
import Bond

protocol BreweryAndBeerCreationProtocol {

    var isQueueRunning: Observable<Bool> { get }
    var breweryElementsRemainingToProcess: Observable<Int> {get}
    var beerElementsRemainingToProcess: Observable<Int> {get}
    func queueBrewery(_ b: BreweryData?)
    func queueBeer(_ b: BeerData?)
    func abandonProcessing() -> Bool
}


extension BreweryAndBeerCreationQueue: ReceiveBroadcastManagedObjectContextRefresh {

    /// All content was delete from the database, so stop loading content into the database
    func contextsRefreshAllObjects() {
        abandonProcessingQueue = true
        classContext?.refreshAllObjects()
    }
}


class BreweryAndBeerCreationQueue: NSObject {

    // MARK: - Constants

    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container

    // Initial responsive load
    private let initialMaxSavesPerLoop: Int = 3
    private let initialRepeatInterval: Double = 2

    // Long running loads
    // System fastest processes is 1.2 records / second
    // Slowest I've seen is .5 records / second and could go lower
    private let longrunningMaxSavesPerLoop: Int = 30
    private let longRunningRepeatInterval: Double = 60

    // Very long running (memory constraiend)
    private let verylongrunningMaxSavesPerLoop: Int = 10
    private let verylongrunningRepeatInterval: Double = 30

    private let maximumSmallRuns = 28
    private let maximumLargeRuns = 100

    // SwiftyBeaver Logging
    //let log = SwiftyBeaver.self

    // MARK: - Variables
    fileprivate var abandonProcessingQueue: Bool = false
    // FIXME
    // A temporary test variable allow us to see the processing queue's state.
    internal var breweryElementsRemainingToProcess: Observable<Int> = Observable<Int>(0)
    internal var beerElementsRemainingToProcess: Observable<Int> = Observable<Int>(0)

    internal var isQueueRunning: Observable<Bool> = Observable<Bool>(false)

    fileprivate var classContext: NSManagedObjectContext? {
        didSet {
            print("You just ste the classContext")
            classContext?.automaticallyMergesChangesFromParent = true
            classContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
            print("Class Context didSet exited")
        }
    }

    private var currentMaxSavesPerLoop: Int = 0
    private var currentRepeatInterval: Double = 0

    private var loopCounter: Int = 0

    fileprivate var mediatorObserver: MediatorBusyObserver?

    private var workTimer: Timer?

    private var breweryDispatchQueue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
    private var brewerySerialQueue = DispatchQueue.global(qos: .background)

    fileprivate var runningBreweryQueue = [BreweryData]()
    fileprivate var runningBeerQueue = [(BeerData,Int)]()


    // MARK: - Functions

    internal class func sharedInstance() -> BreweryAndBeerCreationProtocol {
        struct Singleton {
            static var sharedInstance = BreweryAndBeerCreationQueue()
        }
        return Singleton.sharedInstance
    }


    private func add(brewery newBrewery: Brewery, toStyleID: String, context: NSManagedObjectContext) {
        autoreleasepool {
            do {
                // Adds the brewery to the style for easier searching
                let styleRequest: NSFetchRequest<Style> = Style.fetchRequest()
                styleRequest.sortDescriptors = []
                styleRequest.predicate = NSPredicate(format: "id == %@", toStyleID)
                let resultStyle = try context.fetch(styleRequest)
                resultStyle.first?.addToBrewerywithstyle(newBrewery)
            } catch let error {
                //log.error("There was an error saving brewery to style\(error.localizedDescription)")
            }
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


    private func decideOnDownloadingImage(fromURL: String?,
                                          forType: ImageDownloadType,
                                          forID: String) {
        if let url = fromURL {
            DispatchQueue.global(qos: .utility).async {
                if let nsurl = NSURL(string: url) {
                    BreweryDBClient.sharedInstance().downloadImageToCoreData(forType: forType,
                                                                             aturl: nsurl ,
                                                                             forID: forID)
                }
            }
        }
    }


    private func decideOnMaximumRecordsPerLoop(queueCount: Int) -> Int {
        var maxSave = currentMaxSavesPerLoop
        if queueCount < maxSave {
            maxSave = queueCount
        }
        return maxSave
    }


    private override init() {
        super.init()
        //brewerySerialQueue
        //workTimer = Timer.scheduledTimer(timeInterval: currentRepeatInterval,
        //                                         target: self,
        //                                         selector: #selector(self.startOfProcessQueue),
        //                                         userInfo: nil,
        //                                         repeats: true)
        classContext = container?.newBackgroundContext()
        classContext!.automaticallyMergesChangesFromParent = true
        classContext!.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)

        (Mediator.sharedInstance() as BroadcastManagedObjectContextRefresh).registerManagedObjectContextRefresh(self)
        mediatorObserver = Mediator.sharedInstance() as MediatorBusyObserver
        switchToInitialRunningDataLoad()
        bindProcessQueueToStartTimer()

        Timer.scheduledTimer(withTimeInterval: 5, repeats: true){
            [unowned self] timer in
            print("timer fired")
            let workItem = DispatchWorkItem {
                guard (self.classContext?.hasChanges)! else {
                    return
                }
                do {
                    //self.classContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
                    self.breweryElementsRemainingToProcess.value -= (self.classContext?.insertedObjects.count) ?? 0
                    try self.classContext?.save()
                    print("Successfully saved")
                } catch let error {
                    print("---> Error saving Brewery\(error.localizedDescription)")
                    //log.error("There was and error saving brewery \(error.localizedDescription)")
                }
            }
            self.brewerySerialQueue.sync(execute: workItem)
        }
    }


    private func bindProcessQueueToStartTimer() {
//        breweryElementsRemainingToProcess.observeNext {
//            [unowned self] value in
//            //if !self.isQueueRunning.value {
//                //self.startWorkTimer()
//            ///}
//        }
//        beerElementsRemainingToProcess.observeNext {
//            [unowned self] value in
//            if !self.isQueueRunning.value{
//
//            }
//        }
    }


    private func possibleNewDequeBeerLoop() {
        let tempContext = container?.newBackgroundContext()
        while runningBeerQueue.count > 0 {

            let workItem = DispatchWorkItem {
                guard let (lbeer,lattempt) = self.runningBeerQueue.first else {
                    return
                }
                let _ = self.runningBeerQueue.removeFirst()
                self.beerElementsRemainingToProcess.value -= 1
                let beer:BeerData? = lbeer
                let attempt: Int? = lattempt
                guard let breweryID = beer?.breweryID else {
                    // FIXME: This break doesn't seem right
                    return
                }
                let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                request.sortDescriptors = []
                request.predicate = NSPredicate(format: "id == %@", breweryID)

                do {
                    let brewers = try tempContext?.fetch(request)

                    // Request did not find breweries
                    guard brewers?.count == 1 else {
                        self.reinsertBeer(beer!,attempt!)
                        return
                    }

                    if let styleID = beer!.styleID {
                        self.add(brewery: (brewers?.first)!, toStyleID: styleID,
                                 context: tempContext!)
                    }

                    let createdBeer = try Beer(data: beer!, context: tempContext!)
                    createdBeer.brewer = brewers?.first

                    self.decideOnDownloadingImage(fromURL: beer!.imageUrl, forType: .Beer, forID: (beer?.id!)!)

                } catch let error {

                    //SwiftyBeaver.self.error("There was an error saving brewery to style\(error.localizedDescription)")
                    // FIXME: What should you do if we can't get a
                    //fatalError()
                }

                // FIXME: Temporary test code
                //self.beerElementsRemainingToProcess.value -= 1
                // Help slow saving and memory leak.
                do {
                    if (tempContext?.hasChanges)! {
                        try tempContext?.save()
                    }
                    // Reset to help running out of memory
                    //tempContext?.reset()
                } catch let error {

                }
            }
            self.brewerySerialQueue.sync(execute: workItem)
        }
    }
    //        tempContext?.perform {
    //            autoreleasepool {
    //                beerLoop: for _ in 1...maxSave {
    //
    //                    guard self.continueProcessingAfterContextRefresh() else {
    //                        break beerLoop
    //                    }
    //
    //                    // If we select a brewery, then only beers will be generated.
    //                    // Therefore we must attach the styles to the breweries at a beer by beer level.
    //
    //                    var beer: BeerData?
    //                    var attempt: Int?
    //                    guard self.runningBeerQueue.count > 0 else {
    //                        continue
    //                    }
    //                    let workItem = DispatchWorkItem {
    //                        let (lbeer,lattempt) = self.runningBeerQueue.removeFirst()
    //                        beer = lbeer
    //                        attempt = lattempt
    //                    }
    //
    //
    //                    guard let breweryID = beer!.breweryID else {
    //                        continue
    //                    }
    //
    //  NSLog("There was and error saving brewery to style\(error.localizedDescription)")
    //            }
    //        }
    //    }

    private func subprocessBeerLoop(_ maxSave: Int) {
        // Processing Beers
        let tempContext = container?.newBackgroundContext()
        tempContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
        tempContext?.automaticallyMergesChangesFromParent = true

        tempContext?.perform {
            autoreleasepool {
                beerLoop: for _ in 1...maxSave {

                    guard self.continueProcessingAfterContextRefresh() else {
                        break beerLoop
                    }

                    // If we select a brewery, then only beers will be generated.
                    // Therefore we must attach the styles to the breweries at a beer by beer level.

                    var beer: BeerData?
                    var attempt: Int?
                    guard self.runningBeerQueue.count > 0 else {
                        continue
                    }
                    let workItem = DispatchWorkItem {
                        let (lbeer,lattempt) = self.runningBeerQueue.removeFirst()
                        beer = lbeer
                        attempt = lattempt
                    }

                    self.brewerySerialQueue.sync(execute: workItem)

                    guard let breweryID = beer!.breweryID else {
                        continue
                    }

                    let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                    request.sortDescriptors = []
                    request.predicate = NSPredicate(format: "id == %@", breweryID)

                    do {
                        let brewers = try tempContext?.fetch(request)

                        // Request did not find breweries
                        guard brewers?.count == 1 else {
                            self.reinsertBeer(beer!,attempt!)
                            continue
                        }

                        if let styleID = beer!.styleID {
                            self.add(brewery: (brewers?.first)!, toStyleID: styleID,
                                     context: tempContext!)
                        }

                        let createdBeer = try Beer(data: beer!, context: tempContext!)
                        createdBeer.brewer = brewers?.first

                        self.decideOnDownloadingImage(fromURL: beer!.imageUrl, forType: .Beer, forID: (beer?.id!)!)

                    } catch let error {
                        
                        //SwiftyBeaver.self.error("There was an error saving brewery to style\(error.localizedDescription)")
                        // FIXME: What should you do if we can't get a
                        //fatalError()
                    }
                    
                    // FIXME: Temporary test code
                    self.beerElementsRemainingToProcess.value -= 1
                }
            }
            // Help slow saving and memory leak.
            do {
                if (tempContext?.hasChanges)! {
                    try tempContext?.save()
                }
                // Reset to help running out of memory
                tempContext?.reset()
            } catch let error {
                NSLog("There was and error saving brewery to style\(error.localizedDescription)")
            }
        }
    }

    private func possiblesubprocessBreweryLoop() {
        autoreleasepool {
            //                    guard self.continueProcessingAfterContextRefresh() else {
            //                        break breweryLoop
            //                    }
            //                    guard self.runningBreweryQueue.count > 0 else {
            //                        continue
            //                    }
            //while runningBreweryQueue.count > 0 {
            print("possiblesubprocessBreweryLoopCalled")
            let workItem = DispatchWorkItem {
                print("----> Work item running BreweryConsumerLoop")
                guard let breweryData = self.runningBreweryQueue.first else {
                    return // are these running against the same
                }
                self.runningBreweryQueue.removeFirst() // Delete record from queue
                self.classContext?.perform {
                    let newBrewery = Brewery(with: breweryData, context: self.classContext!)
                    // If brewery has a style id; add the brewery to that style.
                    if let styleID = breweryData.styleID {
                        self.add(brewery: newBrewery,
                                 toStyleID: styleID,
                                 context: self.classContext!)
                    }
                    self.decideOnDownloadingImage(fromURL: breweryData.imageUrl,
                                                  forType: .Brewery,
                                                  forID: breweryData.id!)
                    // FIXME: Temporary test code
                    //self.breweryElementsRemainingToProcess.value -= 1
                    print("Should have decremented brewery Left to process to \(self.breweryElementsRemainingToProcess.value)")
                    // Save group of breweries and style data.
//                    do {
//                        //self.classContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
//                        try self.classContext?.save()
//                    } catch let error {
//                        print("---> Error saving Brewery\(error.localizedDescription)")
//                        //log.error("There was and error saving brewery \(error.localizedDescription)")
//                    }
                    //self.classContext?.reset() // returns cntext to it's base state; this was here to fix memory leak
                    //if !self.runningBeerQueue.isEmpty {
                    if !self.runningBreweryQueue.isEmpty {
                        print("Loop not empty so saving another try")
                        self.possiblesubprocessBreweryLoop()
                    }
                }
            }
            brewerySerialQueue.sync(execute: workItem)
            print("possiblesubprocessBreweryLoop() Completed Queing a work item to process all breweries in queue.")
            //}
        }
    }


    private func subprocessBreweryLoop(_ maxSave: Int) {
        classContext?.performAndWait {

            autoreleasepool {
                breweryLoop: for _ in 1...maxSave {
                    guard self.continueProcessingAfterContextRefresh() else {
                        break breweryLoop
                    }
                    guard self.runningBreweryQueue.count > 0 else {
                        continue
                    }
                    var breweryData: BreweryData?
                    let workItem = DispatchWorkItem {
                        breweryData = self.runningBreweryQueue.removeFirst()
                    }
                    brewerySerialQueue.sync(execute: workItem)
                    let newBrewery = Brewery(with: breweryData as! BreweryData, context: self.classContext!)
                    // If brewery has a style id; add the brewery to that style.
                    if let styleID = breweryData?.styleID {
                        self.add(brewery: newBrewery,
                                 toStyleID: styleID,
                                 context: self.classContext!)
                    }

                    self.decideOnDownloadingImage(fromURL: breweryData!.imageUrl,
                                                  forType: .Brewery,
                                                  forID: breweryData!.id!)

                    // FIXME: Temporary test code
                    breweryElementsRemainingToProcess.value -= 1

                }
            }
            // Save group of breweries and style data.
            do {
                //self.classContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
                try self.classContext?.save()
            } catch let error {
                //log.error("There was and error saving brewery \(error.localizedDescription)")
            }
            self.classContext?.reset()
        }
    }


    // Periodic method to save breweries and beers
    @objc private func startOfProcessQueue() {
        // FIXME
        print("Attempting to startOfProcessQueue")
        // This function will save all breweries before saving beers.
        // FIXME: May not need this.
        // classContext?.automaticallyMergesChangesFromParent = true
        self.loopCounter += 1
        if self.loopCounter > self.maximumSmallRuns {
            self.switchToLongRunningDataLoad()
        } else if self.loopCounter > self.maximumLargeRuns {
            self.switchToVeryLongRunningDataLoad()
        }

        // Save breweries one at time. Batch saving generates conflict errors.
        //let dq = DispatchQueue(label: "BreweryAndBeerProcessingSerialQueue")
        //dq
        DispatchQueue.global(qos: .userInitiated).async {
            // FIXME PROPOSED SOLUTION
            while self.runningBreweryQueue.count > 0 {

                //FIXME
                print("Async running process queue as .userInitiated")
                guard !self.runningBreweryQueue.isEmpty || !self.runningBeerQueue.isEmpty else {
                    // Both queues are empty stop timer
                    self.reinitializeLoadParameter()
                    return
                }

                // This adjusts the maximum amount of processing per data load
                // Low in the beginning then increasing
                var maxSave: Int!
                maxSave = self.decideOnMaximumRecordsPerLoop(queueCount: self.runningBreweryQueue.count)

                // Processing Breweries
                if !self.runningBreweryQueue.isEmpty { // Should we skip brewery processing
                    //self.subprocessBreweryLoop(maxSave)
                    self.possiblesubprocessBreweryLoop()
                }

            } // End of while loop
            // Begin to process beers only if breweries are done.
            guard self.runningBreweryQueue.isEmpty else {
                // Else Wait for timer to fire again and process some more
                // Breweries
                return
            }

            // Reset the maximum records to process
            // FIXME temporarily comment out
            //maxSave = self.decideOnMaximumRecordsPerLoop(queueCount: self.runningBeerQueue.count)

            // Process Beers
            if !self.runningBeerQueue.isEmpty { // We skip beer processing when
                // FIXME temporarily change
                //self.subprocessBeerLoop(maxSave)
                //self.subprocessBeerLoop(1000)
                self.possibleNewDequeBeerLoop()
            }
            // FIXME
            print("Finished running startOfProcessQueue asynchronously")
        }
    }


    private func reinitializeLoadParameter() {
        switchToInitialRunningDataLoad()
        stopWork()
    }


    private func reinsertBeer(_ beer: BeerData, _ inAttempt: Int) {

        // If we have breweries still running then put beer back
        let attempt = inAttempt
        // This only runs from a DispatchWorkItem
        self.runningBeerQueue.append( (beer,0) )

//        let workItem = DispatchWorkItem {
//        }
//        brewerySerialQueue.sync(execute: workItem)
        beerElementsRemainingToProcess.value += 1
//        if !runningBreweryQueue.isEmpty {
//            let workItem = DispatchWorkItem {
//                self.runningBeerQueue.append( (beer,attempt) )
//            }
//            brewerySerialQueue.sync(execute: workItem)
//        } else { // Out of breweries. Try again 3 times then give up
//            if attempt < 3 {
//                attempt += 1
//                let workItem = DispatchWorkItem {
//                    self.runningBeerQueue.append( (beer,attempt) )
//                }
//                brewerySerialQueue.sync(execute: workItem)
//            }
//        }
    }

    
    fileprivate func startWorkTimer() {
        //        if workTimer == nil {
        //            print("Work timer was nil creating a new scheduled timer")
        //            workTimer = Timer.scheduledTimer(timeInterval: currentRepeatInterval,
        //                                             target: self,
        //                                             selector: #selector(self.startOfProcessQueue),
        //                                             userInfo: nil,
        //                                             repeats: true)
        //        } else {
        //            // FIXME
        //            print("Work timer is not nil")
        //        }
        //        isQueueRunning.value = true
        //        mediatorObserver?.notifyStartingWork()
        //        // FIXME
        //        print("Starting work timer exiting?")
    }


    private func stopWork() {
        //        workTimer?.invalidate()
        //        workTimer = nil
        //        mediatorObserver?.notifyStoppingWork()
        //        loopCounter = 0
        //        isQueueRunning.value = false
        //        print("Stopping work timer")
    }


    private func switchToInitialRunningDataLoad() {
        currentMaxSavesPerLoop = initialMaxSavesPerLoop
        currentRepeatInterval = initialRepeatInterval
    }


    private func switchToLongRunningDataLoad() {
        currentMaxSavesPerLoop = longrunningMaxSavesPerLoop
        currentRepeatInterval = longRunningRepeatInterval
    }


    private func switchToVeryLongRunningDataLoad() {
        //log.info("func \(#function)")
        currentMaxSavesPerLoop = verylongrunningMaxSavesPerLoop
        currentRepeatInterval = verylongrunningRepeatInterval
    }

}


//  MARK: - BreweryAndBeerCreationProtocol Extension

extension BreweryAndBeerCreationQueue: BreweryAndBeerCreationProtocol {

    func abandonProcessing() -> Bool {
        return true
    }

    internal func isBreweryAndBeerCreationRunning() -> Bool {
        if runningBreweryQueue.isEmpty && runningBeerQueue.isEmpty {
            return false
        }
        return true
    }

    // Queues up breweries to be saved
    internal func queueBrewery(_ breweryData: BreweryData?) {
        print("------> queuing brewery")
        // Check to see if brewery exists
        let context = container?.newBackgroundContext()
        let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id== %@", (breweryData?.id)!)
        var breweries: [Brewery]?
        do {
            breweries = try context?.fetch(request)
        } catch let error{
            NSLog("Error finding a brewery because \(error.localizedDescription)")
        }
        guard breweries?.first == nil else {
            // Skip brewery creation when we already have the brewery
            return
        }
        if let localBrewer = breweryData {
            let workItem = DispatchWorkItem {
                self.runningBreweryQueue.append(localBrewer)
            }
            brewerySerialQueue.sync(execute: workItem)
            print("incremented brewery remaining to be processed first")
            // FIXME Temporary test code
            breweryElementsRemainingToProcess.value += 1

            // Schedule the breweryLoop for processing in the future
            possiblesubprocessBreweryLoop()

            // FIXME but the following 2 lines back in.
            //startWorkTimer()
            //startOfProcessQueue()

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
            let attempt: Int = 0
            let workItem = DispatchWorkItem {
                self.runningBeerQueue.append( (beer,0) )
            }
            //brewerySerialQueue.sync(execute: workItem)

            // Deque beers
            //possibleNewDequeBeerLoop()

            //startWorkTimer()
            // FIXME Temporary test code
            beerElementsRemainingToProcess.value += 1
        }
    }
}




