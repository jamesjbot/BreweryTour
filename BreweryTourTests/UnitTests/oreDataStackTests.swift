//
//  CoreDataStackTests.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 7/24/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import XCTest
@testable import BreweryTour

class CoreDataStackTests: XCTestCase {

    var coreDataStackMock = CoreDataStack(modelName: "BreweryTour")

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        coreDataStackMock = nil
    }
    
    func testGettingCountsOfObjectsInCoreData() {
        // Makes sure that the getter does not modify the CoreData's state. 

        // Given:
        let currentResults = coreDataStackMock?.getCountsOfObjectInCoreData()

        // When:
        let anotherSnapshotOfCurrentResults = coreDataStackMock?.getCountsOfObjectInCoreData()

        // Then:
        XCTAssert(currentResults == anotherSnapshotOfCurrentResults)
    }

    func testDeleteAll() {
        // Given:
        // When:
        deleteAll(completion:
            { (success: Bool,results: ResultsOfCoreDataDeletion) -> () in
        // Then:
                XCTAssert(success == true)
                XCTAssert(results.beersDeletedSuccessfully == true )
                XCTAssert(results.breweriesDeletedSuccessfully == true)
                XCTAssert(results.stylesDeletedSuccessfully == true)
            }
        )

    }

    func testSaveAll() {
        // Given:
        let parentContext = coreDataStackMock.parentContext
        XCTAssert(parentContext != nil)
        let parentsPreviousSaveCount = parentContext.getCountsOfObjectInCoreData
        // When:
        saveToFile()
        // Then:
        let parentsPostSaveCount = parentContext.getCountsOfObjectInCoreData
        XCTAssert(parentsPreviousSaveCount != parentsPostSaveCount)
    }



    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
