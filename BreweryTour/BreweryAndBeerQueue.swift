//
//  BreweryAndBeerQueue.swift
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
                  context: NSManagedObjectContext) {
        // Brewery required parameters
        name = inName
        latitude = inLatitude
        longitude = inLongitude
        url = inUrl
        openToThePublic = open
        id = inId
        // Un required parametesr
        favorite = false
        imageUrl = nil
        //completion: ((Brewery) -> Void)?
    }
    // TODO delete this initializer not used.
    internal init() {
        favorite = false
        id = nil
        imageUrl = nil
        latitude = nil
        longitude = nil
        name = nil
        openToThePublic = false
        url = nil
        brewedbeer = nil
        completion = nil
    }

}


struct BeerData {
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


class BreweryAndBeerQueue: NSObject {

    // MARK: Constants

    private let secondsRepeatInterval: Double = 3

    private let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container

    // MARK: Variables

    private var workTimer: Timer!

    private var breweryQueue: DispatchQueue = DispatchQueue.global(qos: .background)

    private var runningBreweryQueue = [BreweryData]()
    private var runningBeerQueue = [BeerData]()

    // MARK: Functions

    required override init() {
        super.init()
        workTimer = Timer.scheduledTimer(timeInterval: secondsRepeatInterval,
                                         target: self,
                                         selector: #selector(self.processQueue),
                                         userInfo: nil,
                                         repeats: true)
    }


    // Periodic method to save breweries and beers
    @objc private func processQueue() {
        // This function will save all breweries before saving beers.
        // This is here because the beer's brewer attribute needs to be set from
        // an inserted brewer otherwise strange errors occur.
        // The only way to merge MO with unique constraints is to save them 
        // one at time. Batch saving generates conflict errors.
        let dq = DispatchQueue.global(qos: .background)
        dq.sync {
            print("Processing breweries: we have \(runningBreweryQueue.count) breweries")
            print("Processing beers: we have \(runningBeerQueue.count) beers")
            guard !runningBreweryQueue.isEmpty || !runningBeerQueue.isEmpty else {
                workTimer.invalidate()
                workTimer = nil
                return
            }
            var maxSave = 325
            if runningBreweryQueue.count < maxSave {
                maxSave = runningBreweryQueue.count
            }

            let abreweryContext = container?.newBackgroundContext()
            abreweryContext?.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyObjectTrumpMergePolicyType)

            if !runningBreweryQueue.isEmpty {
                for _ in 1...maxSave {
                    let b = runningBreweryQueue.removeFirst()
                    _ = Brewery(data: b, context: abreweryContext!)
                    do {
                        try abreweryContext?.save()
                    } catch let err {
                        print(err.localizedDescription)
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
            maxSave = 325
            if runningBeerQueue.count < maxSave {
                maxSave = runningBeerQueue.count
            }

            for _ in 1...maxSave {
                let b = runningBeerQueue.removeFirst()

                let request: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                request.sortDescriptors = []
                request.predicate = NSPredicate(format: "id == %@", b.breweryID!)
                abreweryContext?.performAndWait {
                    do {
                        let results = try request.execute()
                        let outputBeer = Beer(data: b, context: abreweryContext!)
                        outputBeer.brewer = results.first
                        try abreweryContext?.save()
                    } catch let error {
                        print(error.localizedDescription)
                        fatalError()
                    }
                }
            }
        }
    }

    private func startWorkTimer() {
        if workTimer == nil {
            workTimer = Timer.scheduledTimer(timeInterval: secondsRepeatInterval,
                                             target: self,
                                             selector: #selector(self.processQueue),
                                             userInfo: nil,
                                             repeats: true)
        }
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
            runningBeerQueue.append(beer)
        }
    }
}




