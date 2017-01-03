//
//  BreweryAndBeerCreationQueue.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/28/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
import Foundation
import UIKit
import CoreData
import Dispatch

internal struct BreweryData {
    // Brewery required parameters
    var name: String?
    var latitude: String?
    var longitude: String?
    var url: String?
    var openToThePublic: Bool
    var id: String?
    // Unrequired parametesr
    var favorite: Bool
    var imageUrl: String?
    var brewedbeer: NSSet?
    var completion: ((Brewery) -> Void)?
    internal init(inName: String,
                  inLatitude: String,
                  inLongitude: String,
                  inUrl: String,
                  open: Bool,
                  inId: String,
                  inImageUrl: String?) {
        // Brewery required parameters
        name = inName
        latitude = inLatitude
        longitude = inLongitude
        url = inUrl
        openToThePublic = open
        id = inId
        // Un required parametesr
        favorite = false
        imageUrl = inImageUrl
        //completion: ((Brewery) -> Void)?
    }
}


internal struct BeerData {
    var availability: String?
    var beerDescription: String?
    var beerName: String?
    var breweryID: String?
    var id: String?
    var imageUrl: String?
    var isOrganic: Bool
    var styleID: String?
    var abv: String?
    var ibu: String?

    init(inputAvailability : String?,
        inDescription : String?,
        inName : String?,
        inBrewerId : String,
        inId : String,
        inImageURL : String?,
        inIsOrganic : Bool,
        inStyle : String?,
        inAbv : String?,
        inIbu : String?) {
        availability = inputAvailability
        beerDescription = inDescription
        beerName = inName
        breweryID = inBrewerId
        id = inId
        imageUrl = inImageURL
        isOrganic = inIsOrganic
        styleID = inStyle
        abv = inAbv!
        ibu = inIbu!
    }
}

internal protocol BreweryAndBeerCreation {

    func isBreweryAndBeerCreationRunning() -> Bool
    func queueBrewery(_ b: BreweryData?)
    func queueBeer(_ b: BeerData?)
}


class BreweryAndBeerCreationQueue: NSObject {

    // MARK: Constants

    private let secondsRepeatInterval: Double = 2
    private let maxSavesPerLoop: Int = 100

    private let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container

    // MARK: Variables

    private var workTimer: Timer!

    private var breweryQueue: DispatchQueue = DispatchQueue.global(qos: .background)

    fileprivate var runningBreweryQueue = [BreweryData]()
    fileprivate var runningBeerQueue = [(BeerData,Int)]()

    private var abreweryContext: NSManagedObjectContext? {
        didSet {
            abreweryContext?.automaticallyMergesChangesFromParent = true
        }
    }


    // MARK: Functions

    required override init() {
        super.init()
        workTimer = Timer.scheduledTimer(timeInterval: secondsRepeatInterval,
                                         target: self,
                                         selector: #selector(self.processQueue),
                                         userInfo: nil,
                                         repeats: true)
        abreweryContext = container?.newBackgroundContext()
    }


    // Periodic method to save breweries and beers
    @objc private func processQueue() {
        // This function will save all breweries before saving beers.
        // This is here because the beer's brewer attribute needs to be set from
        // an inserted brewer otherwise strange errors occur.
        // The only way to merge MO with unique constraints is to save them
        // Had to move the merge policy assignment closer to the
        // invocation of save because it was not taking.
        abreweryContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)

        // one at time. Batch saving generates conflict errors.
        let dq = DispatchQueue.global(qos: .background)
        dq.sync {
            print("Processing breweries creation: we have \(runningBreweryQueue.count) breweries")
            print("Processing beers creation: we have \(runningBeerQueue.count) beers")
            guard !runningBreweryQueue.isEmpty || !runningBeerQueue.isEmpty else {
                workTimer.invalidate()
                workTimer = nil
                return
            }
            var maxSave = maxSavesPerLoop
            if runningBreweryQueue.count < maxSave {
                maxSave = runningBreweryQueue.count
            }

            //Processing Breweries
            if !runningBreweryQueue.isEmpty {
                for _ in 1...maxSave {
                    let b = runningBreweryQueue.removeFirst()
                    _ = Brewery(data: b, context: abreweryContext!)

                    // We must save everyupdate individually or Unique constraints on the class will not be presever
                    do {
                        try abreweryContext?.save()
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
                return
            }

            // If runningBeerQueue is empty stop
            guard !runningBeerQueue.isEmpty else {
                return
            }
            // Reset the maximum records to process
            maxSave = maxSavesPerLoop
            if runningBeerQueue.count < maxSave {
                maxSave = runningBeerQueue.count
            }


            // Processing Beers
            for _ in 1...maxSave {
                var (beer,attempt) = runningBeerQueue.removeFirst()

                let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                request.sortDescriptors = []
                request.predicate = NSPredicate(format: "id == %@", beer.breweryID!)
                abreweryContext?.performAndWait {
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

                            resultStyle?.first?.addToBrewerywithstyle((brewers?.first)!)
                            print("Added \(brewers?.first?.name) to \(resultStyle?.first?.displayName)")
                            print("this style now has \(resultStyle?.first?.brewerywithstyle?.count) breweries ")
                            let createdBeer = Beer(data: beer, context: self.abreweryContext!)
                            createdBeer.brewer = brewers?.first

                            try self.abreweryContext?.save()
                            print("Style and changes saved")
                            if beer.imageUrl != nil {
                                // If we have image data download it
                                BreweryDBClient.sharedInstance().downloadImageToCoreData(forType: .Beer,                                                                               aturl: NSURL(string: beer.imageUrl!)!,                                                                             forID: beer.id!)
                            }
                        }
                    } catch let error {
                        print(error.localizedDescription)
                        fatalError()
                    }


                }
            }
        }
    }

//    private func testingVerify(beer: BeerData,c: NSManagedObjectContext) {
//        do {
//            // Adds the brewery to the style for easier searching
//            let dContext = c
//            let styleRequest: NSFetchRequest<Style> = Style.fetchRequest()
//            styleRequest.sortDescriptors = []
//            styleRequest.predicate = NSPredicate(format: "id == %@", beer.styleID!)
//            let resultStyle = try dContext.fetch(styleRequest)
//            assert(resultStyle.count == 1)
//            print("Verifying on different context this style now has \(resultStyle.first?.brewerywithstyle?.count)! breweries ")
//        } catch {
//
//        }
//
//    }

    fileprivate func startWorkTimer() {
        if workTimer == nil {
            workTimer = Timer.scheduledTimer(timeInterval: secondsRepeatInterval,
                                             target: self,
                                             selector: #selector(self.processQueue),
                                             userInfo: nil,
                                             repeats: true)
        }
    }
}

extension BreweryAndBeerCreationQueue: BreweryAndBeerCreation {


    internal func isBreweryAndBeerCreationRunning() -> Bool {
        if runningBreweryQueue.isEmpty && runningBeerQueue.isEmpty {
            return false
        }
        return true
    }

    // Queues up breweries to be saved
    internal func queueBrewery(_ b: BreweryData?) {
        if let brewer = b {
            startWorkTimer()
            runningBreweryQueue.append(brewer)
        }
    }


    // Queues up beers to be saved
    internal func queueBeer(_ b: BeerData?) {
        if let beer = b {
            startWorkTimer()
            let attempt = 0
            runningBeerQueue.append( (beer,attempt) )
        }
    }
}




