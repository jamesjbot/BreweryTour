//
//  CoreDataStackTests.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 7/24/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import XCTest
import CoreData
//import Alamofire
//import SwiftyBeaver

@testable import BreweryTour

class CoreDataStackTests: XCTestCase {

    var mockCoredata: Coredata? = nil
    var persistentContainer: NSPersistentContainer? = nil

    
    func setUpInMemoryManagedObjectContext() -> NSManagedObjectContext {

        //let breweryTourModel: NSManagedObjectModel = (coreDataStackMock?.container.managedObjectModel)!

        //let managedObjectModel: NSManagedObjectModel = NSManagedObjectModel(byMerging: [breweryTourModel!])!
        persistentContainer = NSPersistentContainer(name: "BreweryTour")

        persistentContainer?.loadPersistentStores(completionHandler: {
            (storeDescription, error) in
            if (error as NSError?) != nil {
                fatalError("Unresolved error")
            } else {
                print("Persistent container created succesffully \(String(describing: self.persistentContainer?.managedObjectModel.description))")
            }
        })

        return persistentContainer!.newBackgroundContext()
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mockCoredata = MockCoredata()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        mockCoredata = nil
    }



    func testAddingBreweryReflectsInGettingCounts() {

        // Given: 

        // Create a brewery skeleton but not the object
        let breweryData: BreweryData = BreweryData(inName: "Test Brewery",
                                                    inLatitude: "100.00",
                                                    inLongitude: "100.00",
                                                    inUrl: "https://www.google.com",
                                                    open: true,
                                                    inId: "1235456",
                                                    inImageUrl: nil,
                                                    inStyleID: nil)


        // Get a reference baseline of results
        let priorCount = mockCoredata?.getAllNSManagedObjectsOf(type: "Brewery").count
        // When:

        let context = mockCoredata?.context


        // Store new Brewery and Beer in core data
        let _ = Brewery(context: context!)

        //let callBackDelay: TimeInterval = 5000

        // Save the new objects
        let _ = mockCoredata?.handleSavingAndError()


        // Then:
        let newSnapshotOfResults = self.mockCoredata?.getAllNSManagedObjectsOf(type: "Brewery").count

        XCTAssert(newSnapshotOfResults == 1,
                      "We expected 1 breweries but got \(String(describing: newSnapshotOfResults))")
    }


    func testAddingBeerReflectsInCorData() {
        // Create a beer skeleton but not the object
        let beerData = BeerData(inputAvailability : "Seasonal",
                                inDescription : "A strong IPA",
                                inName : "Strong Bier",
                                inBrewerId : "1235456",
                                inId : "12321312",
                                inImageURL : nil,
                                inIsOrganic : true,
                                inStyle : "India Pale Ale",
                                inAbv : "3.0",
                                inIbu : "3.0")

        let context = mockCoredata?.context

        let beer: Beer?
        do {
            beer = try Beer(data: beerData, context: context!)
        }
        catch let error {
            print("There was an error running \(error)")
        }
        let _ = mockCoredata?.handleSavingAndError()

        let newSnapShotOfResults = self.mockCoredata?.getAllNSManagedObjectsOf(type: "Beer").count

        XCTAssert(newSnapShotOfResults == 1, "We expected 1 breweries but got \(String(describing: newSnapShotOfResults))")
    }

}





