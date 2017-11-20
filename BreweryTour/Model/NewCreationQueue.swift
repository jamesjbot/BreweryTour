//
//  NewBreweryAndBeerCreationQueue.swift
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


protocol AcceptsCreationQueue {
    var creationQueue: BreweryAndBeerCreationProtocol? {get set}
    mutating func set(creationQueue: BreweryAndBeerCreationProtocol)
}

extension AcceptsCreationQueue {
    mutating func set(creationQueue: BreweryAndBeerCreationProtocol) {
        self.creationQueue = creationQueue
    }
}

extension NewCreationQueue: ReceiveBroadcastManagedObjectContextRefresh {

    /// All content was delete from the database, so stop loading content into the database
    func contextsRefreshAllObjects() {
        abandonProcessingQueue = true
        newPrivateBackgroundContextForPeriodicallySavingCoreData?.refreshAllObjects()
    }
}


class NewCreationQueue: NSObject {

    // MARK: - Constants
    enum DataType {
        case Beer
        case Brewery
    }

    struct Constants {
        static let BackgroundSaveTimeIntervaliSeconds = 6
        static let Maximum_Attempts_To_Reinsert_Beer_For_Processing = 10
        static let InitialMaxSavesPerLoop: Int = 10

    }

    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container

    private let BackgroundSaveTimerInterval = Constants.BackgroundSaveTimeIntervaliSeconds

    // Initial responsive load
    private let initialRepeatInterval: Double = 2


    // SwiftyBeaver Logging
    //let log = SwiftyBeaver.self

    // MARK: - Variables
    fileprivate var abandonProcessingQueue: Bool = false
    // FIXME
    // A temporary test variable allow us to see the processing queue's state.
    internal var breweryElementsRemainingToProcess: Observable<Int> = Observable<Int>(0)
    internal var beerElementsRemainingToProcess: Observable<Int> = Observable<Int>(0)

    internal var isQueueRunning: Observable<Bool> = Observable<Bool>(false)

    fileprivate var newPrivateBackgroundContextForPeriodicallySavingCoreData: NSManagedObjectContext? {
        didSet {
            print("You just set the classContext")
            newPrivateBackgroundContextForPeriodicallySavingCoreData?.automaticallyMergesChangesFromParent = true
            newPrivateBackgroundContextForPeriodicallySavingCoreData?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)
            print("Class Context Concurrency type \(String(describing: newPrivateBackgroundContextForPeriodicallySavingCoreData?.concurrencyType))")
            print("Class Context didSet exited")
        }
    }

    private var currentMaxSavesPerLoop: Int = 30
    private var currentRepeatInterval: Double = 0

    private var loopCounter: Int = 0

    fileprivate var mediatorObserver: MediatorBusyObserver?

    private var workTimer: Timer?

    private var newCreationDispatchQueue: DispatchQueue = DispatchQueue.global(qos: .utility)
    private var asyncOnlyBrewerySerialQueue = DispatchQueue(label: "Brewer's Serial",
                                                            qos: DispatchQoS.utility,
                                                            attributes: [],
                                                            autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.workItem,
                                                            target: nil)

    private var asyncOnlyProcessingQueue = DispatchQueue(label:"Processing queue")
    private var syncOnlyQueueForAddingItemDataToQueues = DispatchQueue.global(qos: .utility)

    private var asyncQueueForAddedItemsToContext = DispatchQueue(label:"Inserting and updateing queue")

    private var syncOnlyBrewerySerialQueue = DispatchQueue(label: "CoreData sync update",
                                                           qos: .utility,
                                                           attributes: [],
                                                           autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
                                                           target: nil)

    private var contextForEnqueueData: NSManagedObjectContext?
    private var contextForCoreDataQueryOnly: NSManagedObjectContext?

    fileprivate var runningBreweryQueue: SynchronizedArray<BreweryData> = SynchronizedArray<BreweryData>()
    fileprivate var runningBeerQueue = SynchronizedArray<(BeerData,Int)>()


    // MARK: - Functions

    internal class func sharedInstance() -> BreweryAndBeerCreationProtocol {
        struct Singleton {
            static var sharedInstance = NewCreationQueue()
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
                log.error("There was an error saving brewery to style\(error.localizedDescription)")
            }
        }
    }


    private func continueProcessingAfterContextRefresh() -> Bool {
        // We've been told to abandon Processing because of a core data refresh.
        if abandonProcessingQueue {
            syncOnlyQueueForAddingItemDataToQueues.sync {
                runningBeerQueue.removeAll()
                runningBreweryQueue.removeAll()
                abandonProcessingQueue = false
            }
            return false
        }
        return true
    }


    private func downloadImageIfAvailable(fromURL: String?,
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

    private func initialization() {
        contextForEnqueueData = container?.newBackgroundContext()
        contextForCoreDataQueryOnly = container?.viewContext


        newPrivateBackgroundContextForPeriodicallySavingCoreData = container?.newBackgroundContext()
        print("Concurrency type: \(String(describing: newPrivateBackgroundContextForPeriodicallySavingCoreData))")
        newPrivateBackgroundContextForPeriodicallySavingCoreData!.automaticallyMergesChangesFromParent = true
        newPrivateBackgroundContextForPeriodicallySavingCoreData!.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)

        (Mediator.sharedInstance() as BroadcastManagedObjectContextRefresh).registerManagedObjectContextRefresh(self)
        mediatorObserver = Mediator.sharedInstance() as MediatorBusyObserver
    }

    func threadinfo() {
//        print("\nMain:\(Thread.isMainThread)")
//        print("multithreaded:\(Thread.isMultiThreaded())")
//        print("Thread:\(Thread.current)")
//        print("Priority:\(Thread.threadPriority())")
    }

    private override init() {
        super.init()
        initialization()
        // Independent saving code
        Timer.scheduledTimer(withTimeInterval: TimeInterval(BackgroundSaveTimerInterval), repeats: true){
            timer in
            self.subprocessBreweryLoop()
            self.subprocessBeerLoop()
            self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.perform {
                print("Successfully entered a perform in timer <------")
            }
//            DispatchQueue(label: "Duh inline").async {
//                self.subprocessBreweryLoop()
//                self.subprocessBeerLoop()
//            }
            print("timer fired")
            self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.performAndWait {
                guard (self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.hasChanges)! else {
                    return
                }
                self.newPrivateBackgroundContextForPeriodicallySavingCoreData!.perform {
                    do {
                        self.breweryElementsRemainingToProcess.value -= (self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.insertedObjects.count) ?? 0
                        try self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.save()
                        print("Successfully saved")
                    } catch let error {
                        print("---> Error saving Brewery\(error.localizedDescription)")
                        //log.error("There was and error saving brewery \(error.localizedDescription)")
                    }
                }}}
    }


    private func subprocessBeerLoop() {

        asyncQueueForAddedItemsToContext.async {
            self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.perform {
                var currentProcessed = 0
                while currentProcessed < Constants.InitialMaxSavesPerLoop {
                    currentProcessed += 1
                    guard let (lbeer,lattempt) = self.runningBeerQueue.first() else {
                        return
                    }

                    let _ = self.runningBeerQueue.removeAtIndex(index: 0)

                    let beer:BeerData? = lbeer
                    let attempt: Int? = lattempt

                    guard let breweryID = beer?.breweryID else {
                        // FIXME: This break doesn't seem right
                        print("Inappropriate exit")
                        return
                    }

                    let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                    request.sortDescriptors = []
                    request.predicate = NSPredicate(format: "id == %@", breweryID)

                    do {
                        let brewers = try self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.fetch(request)

                        // Request did not find breweries
                        guard brewers?.count == 1 else {
                            self.reinsertBeer(beer!,attempt!)
                            log.info("Found \(String(describing: brewers?.count)) breweries; Reinserting beer because single brewery not found")
                            return
                        }

                        if let styleID = beer!.styleID {
                            self.add(brewery: (brewers?.first)!, toStyleID: styleID,
                                     context: self.newPrivateBackgroundContextForPeriodicallySavingCoreData!)
                            print("Beer has been saved to moc scatchpad")
                        }

                        let createdBeer = try Beer(data: beer!, context:
                            self.newPrivateBackgroundContextForPeriodicallySavingCoreData!)
                        createdBeer.brewer = brewers?.first
                        print("Running beer queue at end of loop is \(self.runningBeerQueue.count)")

                        // FIXME: What does this do?
                        //                    if !(self.runningBeerQueue.count == 0) {
                        //                        print("Loop not empty so queing another time around the loop")
                        //                        self.scheduleARunOfBeerLoopOnAsyncOnly()
                        //                    }

                        self.downloadImageIfAvailable(fromURL: beer!.imageUrl, forType: .Beer, forID: (beer?.id!)!)

                    } catch let error {
                        log.error("There was an error saving beer \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func subprocessBreweryLoop() {

        guard let breweryData = self.runningBreweryQueue.first() else {
            return // because we have no brewery to process
        }
        self.newPrivateBackgroundContextForPeriodicallySavingCoreData?.perform {

            // Create brewery
            let newBrewery = Brewery(with: breweryData, context: self.newPrivateBackgroundContextForPeriodicallySavingCoreData!)

            // If brewery has a style id; add the brewery to that style.
            if let styleID = breweryData.styleID {
                self.add(brewery: newBrewery,
                         toStyleID: styleID,
                         context: self.newPrivateBackgroundContextForPeriodicallySavingCoreData!)
            }

            self.downloadImageIfAvailable(fromURL: breweryData.imageUrl,
                                          forType: .Brewery,
                                          forID: breweryData.id!)

            // Remove the brewery from processing queue
            let _ = self.syncOnlyQueueForAddingItemDataToQueues.sync {
                if self.runningBreweryQueue.count > 0 {
                    self.runningBreweryQueue.removeAtIndex(index: 0) // Delete record from queueR
                }
            }
        }
    }

//    private func scheduleARunOfBeerLoopOnAsyncOnly() {
//        asyncOnlyBrewerySerialQueue.after(when: 2) {
//            [unowned self] in
//            self.possibleNewDequeBeerLoop()
//        }
//    }


    private func reinsertBeer(_ beer: BeerData, _ inAttempt: Int) {
        guard inAttempt < Constants.Maximum_Attempts_To_Reinsert_Beer_For_Processing else {
            log.info("A Beer was skipped due to too many attempts at processing.")
            return
        }
        // If we have breweries still running then put beer back
        let attempt = inAttempt + 1
        // This only runs from a DispatchWorkItem
        self.runningBeerQueue.append(newElement:  (beer, attempt) )
    }


    private func synchronizedAccessToList(type: DataType, data: AnyObject) {
        switch type {
        case DataType.Beer:
            syncOnlyQueueForAddingItemDataToQueues.sync {
                runningBeerQueue.append(newElement: (data as! BeerData, 0 ))
            }
        case DataType.Brewery:
            syncOnlyQueueForAddingItemDataToQueues.sync {
                runningBreweryQueue.append(newElement: data as! BreweryData)
            }
        }
    }
}


//  MARK: - BreweryAndBeerCreationProtocol Extension

extension NewCreationQueue: BreweryAndBeerCreationProtocol {

    func abandonProcessing() -> Bool {
        return true
    }

    // Queues up breweries to be saved
    internal func queueBrewery(_ breweryData: BreweryData?) {

        // Check to see if brewery exists
        contextForCoreDataQueryOnly?.perform {
            let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
            request.sortDescriptors = []
            request.predicate = NSPredicate(format: "id== %@", (breweryData?.id)!)
            var breweries: [Brewery]?
            do {
                breweries = try self.contextForCoreDataQueryOnly?.fetch(request)
            } catch let error{
                log.error("Error finding a brewery because \(error.localizedDescription)")
            }

            guard breweries?.first == nil else {
                // Skip brewery creation when we already have the brewery
                return
            }

            if let localBrewer = breweryData {
                // serialQueue to enqueue onto the queue serial queue processes
                self.synchronizedAccessToList(type: DataType.Brewery, data: localBrewer as AnyObject)

                // Schedule the breweryLoop for processing in the future
                // FIXME: is this needed
                self.subprocessBreweryLoop()
            }
        }
    }


    // Queues up beers to be saved
    internal func queueBeer(_ beerData: BeerData?) {

        log.info("queueBeer called")
        // Check to see if beer exists
        contextForCoreDataQueryOnly?.perform {

            let request: NSFetchRequest<Beer> = Beer.fetchRequest()
            request.sortDescriptors = []
            request.predicate = NSPredicate(format: "id == %@", (beerData?.id)!)
            var beers: [Beer]?

            do {
                beers = try self.contextForCoreDataQueryOnly?.fetch(request)
            } catch let error{
                log.error("Error finding a Beer because \(error.localizedDescription)")
            }

            guard beers?.first == nil else {
                log.info("We found the beer, no need to requeue it")
                // Skip beer creation when we already have the beer
                return
            }

            if let beer = beerData {
                let _: Int = 0
                self.synchronizedAccessToList(type: DataType.Beer, data: beer as AnyObject)

                // FIXME Temporary test code
                self.beerElementsRemainingToProcess.value += 1

                self.subprocessBeerLoop()
            }
        }
    }
}
