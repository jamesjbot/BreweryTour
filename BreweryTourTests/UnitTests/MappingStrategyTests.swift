//
//  MappingStrategyTests.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 7/29/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import XCTest
import CoreData
import CoreLocation
import MapKit

@testable import BreweryTour


protocol Coredata {

    var persistentContainer: NSPersistentContainer? { get }
    var context: NSManagedObjectContext? { get }
    func createNSManagedObject(entityName: String, name: String) -> NSManagedObject?
    func handleSavingAndError() -> Bool
    func getAllNSManagedObjectsOf(type: String) -> [NSManagedObject]
}


class MappingStrategyTests: XCTestCase {

    var mockCoreData: Coredata? = nil
    var currentMapStrategyUnderTest: MapAnnotationProvider?

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        mockCoreData = MockCoredata()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        mockCoreData = nil
    }

    func testCreatingBreweryFromBreweryData() {
        // Create brewery
        let breweryData: BreweryData = BreweryData(inName: "Test Brewery",
                                                   inLatitude: "100.00",
                                                   inLongitude: "100.00",
                                                   inUrl: "https://www.google.com",
                                                   open: true,
                                                   inId: "1235456",
                                                   inImageUrl: nil,
                                                   inStyleID: nil)

        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()
        let context = mockCoreData?.context

        // When:
        // Create Brewery from Brewery data
        Brewery(with: breweryData, context: context!)

        currentMapStrategyUnderTest = AllBreweriesMapStrategy(view: dummyMapView,
                                                              location: dummyCenterLocation,
                                                              maxPoints: 3,
                                                              inputContext: (mockCoreData?.context)!)


        // Then:
        let breweries = currentMapStrategyUnderTest?.getBreweries()
        XCTAssert(breweries?.count == 1)
    }


    func testCreatingBeerFromBeerDataWillNotCreateABreweryObject() {

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

        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()
        let context = mockCoreData?.context

        // When:
        // Create Brewery from Brewery data
        let _ = try? Beer(data: beerData, context: context!)

        currentMapStrategyUnderTest = AllBreweriesMapStrategy(view: dummyMapView,
                                                              location: dummyCenterLocation,
                                                              maxPoints: 3,
                                                              inputContext: (mockCoreData?.context)!)

        let breweries = currentMapStrategyUnderTest?.getBreweries()

        // Then: There should be no effect on the number of breweries created
        XCTAssert(breweries?.count == 0)
    }



    func testSingleBreweryStrategy() {
        // Given:
        let brewery = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "SingleMalt")
        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()

        // fixme:
        _ = Brewery()
        currentMapStrategyUnderTest = SingleBreweryMapStrategy(b: brewery as! Brewery,
                                                               view: dummyMapView,
                                                               location: dummyCenterLocation)

        // When: We need to update the map view
        let breweries = currentMapStrategyUnderTest?.getBreweries()

        let mkannotation = currentMapStrategyUnderTest?.convertBreweryToAnnotation(breweries: breweries!)

        currentMapStrategyUnderTest?.send(annotations: mkannotation!, to: dummyMapView)

        // Then: The dummyMapView should receive the annotation we sent.
        XCTAssertTrue(dummyMapView.hasReceivedAnnotations)
    }


    func testAllBreweriesMapStrategy() {
        // Given: Making 3 breweries
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "SingleMalt")
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "New York Brewery")
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery")
        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()
        currentMapStrategyUnderTest = AllBreweriesMapStrategy(view: dummyMapView,
                                                              location: dummyCenterLocation,
                                                              maxPoints: 3,
                                                              inputContext: (mockCoreData?.context)!)
        // When: we send the annotations to the dummyMapView
        let breweries = currentMapStrategyUnderTest?.getBreweries()
        let mkannotation = currentMapStrategyUnderTest?.convertBreweryToAnnotation(breweries: breweries!)
        currentMapStrategyUnderTest?.send(annotations: mkannotation!, to: dummyMapView)

        // Then: the dummyMapView should receive those annotations.
        XCTAssertTrue(dummyMapView.hasReceivedAnnotations)
    }


    func testAllBreweriesMapStrategyNewBreweryAddedToCoredata() {

        // Given: We have some breweries

        // Create some breweries
        let _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "SingleMalt")
        let _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "New York Brewery")

        // Attach the dummy inputs
        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()

        // Create mapping strategy
        currentMapStrategyUnderTest = AllBreweriesMapStrategy(view: dummyMapView,
                                                              location: dummyCenterLocation,
                                                              maxPoints: 3,
                                                              inputContext: (mockCoreData?.context)!)
        // Prepare for asynchronous updates
        let expectation = XCTestExpectation(description: "Dummy")
        dummyMapView.promise = expectation


        // When: We add a new brewery

        let _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery")

        let _ = mockCoreData?.handleSavingAndError()

        // Then: Breweries should go up by 1
        wait(for: [expectation], timeout: 5000)

        let after = dummyMapView.previousAmountOfAnnotation.removeLast()
        let before = dummyMapView.previousAmountOfAnnotation.removeLast()
        XCTAssert( ( (before + 1) == after ), "Before and after are not incremental")
    }


    func testStyleMapStrategy() {

        // Given:
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "SingleMalt")
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "New York Brewery")


        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()

        let aStyle = mockCoreData?.createNSManagedObject(entityName: "Style", name: "IPA Style")
        let ipaBrewery = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery")
        (aStyle as! Style).addToBrewerywithstyle(ipaBrewery as! Brewery)

        currentMapStrategyUnderTest = StyleMapStrategy(style: aStyle as? Style,
                                                       view: dummyMapView,
                                                       location: dummyCenterLocation,
                                                       maxPoints: 3,
                                                       inputContext: (mockCoreData?.context)!)
        // When:
        let breweries = currentMapStrategyUnderTest?.getBreweries()
        let mkannotation = currentMapStrategyUnderTest?.convertBreweryToAnnotation(breweries: breweries!)
        currentMapStrategyUnderTest?.send(annotations: mkannotation!, to: dummyMapView)

        // Then:
        XCTAssertTrue(dummyMapView.hasReceivedAnnotations)
    }


    func testStyleMapStrategyDynamicallyAddingNewBreweries() {

        // Given:
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "SingleMalt")
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "New York Brewery")


        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()

        let aStyle = mockCoreData?.createNSManagedObject(entityName: "Style", name: "IPA Style")
        let ipaBrewery = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery")
        (aStyle as! Style).addToBrewerywithstyle(ipaBrewery as! Brewery)

        currentMapStrategyUnderTest = StyleMapStrategy(style: aStyle as? Style,
                                                       view: dummyMapView,
                                                       location: dummyCenterLocation,
                                                       maxPoints: 3,
                                                       inputContext: (mockCoreData?.context)!)
        let expectation = XCTestExpectation(description: "Dummy")
        dummyMapView.promise = expectation

        // When: We add a new brewery

        let brewery2 = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery2")
        let brewery3 = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery3")

        let _ = mockCoreData?.handleSavingAndError()

        (aStyle as! Style).addToBrewerywithstyle(brewery2 as! Brewery)
        (aStyle as! Style).addToBrewerywithstyle(brewery3 as! Brewery)

        let _ = mockCoreData?.handleSavingAndError()

        // Then: Breweries should go up by 2
        wait(for: [expectation], timeout: 5)

        let after = dummyMapView.previousAmountOfAnnotation.removeLast()
        let before = dummyMapView.previousAmountOfAnnotation.removeLast()
        XCTAssert( ( (before + 2) == after ), "Before and after are not incremental \(before):\(after)")
    }


    func testStyleMapFetch() {

        // Given:
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "SingleMalt")
        _ = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "New York Brewery")

        let dummyMapView = DummyMapView()
        let dummyCenterLocation = CLLocation()

        let aStyle = mockCoreData?.createNSManagedObject(entityName: "Style", name: "IPA Style")

        let ipaBrewery = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA Brewery")
        let secondIpaBrewery = mockCoreData?.createNSManagedObject(entityName: "Brewery", name: "IPA2 Brewery")

        (aStyle as! Style).addToBrewerywithstyle(ipaBrewery as! Brewery)
        (aStyle as! Style).addToBrewerywithstyle(secondIpaBrewery as! Brewery)

        let currentMapStrategyUnderTest:FetchableStrategy =
            StyleMapStrategy(style: aStyle as? Style,
                                                       view: dummyMapView,
                                                       location: dummyCenterLocation,
                                                       maxPoints: 3,
                                                       inputContext: (mockCoreData?.context)!)

        let breweries = currentMapStrategyUnderTest.getBreweries()

        XCTAssert( breweries.count == 2, "The breweries were not correctly grabbed")
    }
}


class DummyMapView: MapAnnotationReceiver {
    var hasReceivedAnnotations: Bool = false
    var previousAmountOfAnnotation = [Int]()
    var promise: XCTestExpectation?
    func updateMap(withAnnotations annotations: [MKAnnotation]) {
        previousAmountOfAnnotation.append(annotations.count)
        hasReceivedAnnotations = false
        promise?.fulfill()
        if annotations.count > 0 {
            hasReceivedAnnotations = true
        }
    }

}


class MockCoredata: Coredata {

    var persistentContainer: NSPersistentContainer?
    var context: NSManagedObjectContext?


    init(completionClosure: (() -> ())? = nil) {

        guard let modelURL = Bundle.main.url(forResource: "BreweryTour", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }

        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        assert(mom != nil)

        persistentContainer = NSPersistentContainer(name: "BreweryTour",
                                                    managedObjectModel: mom)
        assert(persistentContainer != nil)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer?.persistentStoreDescriptions = [description]

        persistentContainer?.loadPersistentStores() { (description, error) in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
            completionClosure?()
        }
        assert(persistentContainer != nil)
        context = persistentContainer?.newBackgroundContext()
        assert(context != nil)
    }


    func createNSManagedObject(entityName: String,
                               name: String) -> NSManagedObject? {

        var newMObject: NSManagedObject? = nil

        if let entityDescription = NSEntityDescription.entity(forEntityName: entityName, in: context!) {
            newMObject = makeCoredataManagedObject(entityName: entityName,
                                                   entityDescription: entityDescription,
                                                   name: name)
        }
        return newMObject
    }


    func getAllNSManagedObjectsOf(type: String) -> [NSManagedObject] {

        var request: NSFetchRequest<NSFetchRequestResult>?

        switch type {
        case "Beer":
            let local: NSFetchRequest<Beer> = Beer.fetchRequest()
            request = local as? NSFetchRequest<NSFetchRequestResult>
        case "Brewery":
            let local: NSFetchRequest<Brewery> = Brewery.fetchRequest()
            request = local as? NSFetchRequest<NSFetchRequestResult>
        case "Style":
            request = Style.fetchRequest()
        default:
            fatalError("Unknow NSManagedObject type")
            break
        }
        assert(request != nil)
        let results = try? context?.fetch(request!)
        return results as! [NSManagedObject]
    }



    func makeCoredataManagedObject(entityName: String,
                                   entityDescription: NSEntityDescription,
                                   name: String) -> NSManagedObject? {

        var newMObject: NSManagedObject? = nil

        switch entityName {
        case "Beer":
            newMObject = Beer(entity: entityDescription, insertInto: context)
            (newMObject as! Beer).beerName = intToAlphabetCharacter(Int(arc4random_uniform(26) + 1))
            break
        case "Brewery":
            newMObject = Brewery(entity: entityDescription, insertInto: context)
            (newMObject as! Brewery).name = intToAlphabetCharacter(Int(arc4random_uniform(26) + 1))
            (newMObject as! Brewery).latitude = String(arc4random_uniform(100))
            (newMObject as! Brewery).longitude = String(arc4random_uniform(100))
            break
        case "Style":
            let style = Style(entity: entityDescription, insertInto: context)
            style.displayName = name
            style.id = "12345"
            newMObject = style
            break
        default:
            fatalError("You typed in the wrong Entity name")
            break
        }

        return newMObject
    }



    func intToAlphabetCharacter(_ number: Int) -> String {
        guard number > 0 && number <= 26 else {
            return "Error"
        }
        return String(Character((UnicodeScalar(UInt32(number) + (("@".unicodeScalars.first?.value)!)))!))
    }
    
    
    func handleSavingAndError() -> Bool{
        
        do {
            try context?.save()
            return true
        }
        catch let error {
            print("Unable to save changes\(error)")
            return false
        }
    }
}

// MARK: - Unit test helper protocol
protocol CoreDataStackAccess {
    // This is a helper protocol for Unit Testing
    // The access to the database has to be interuptable.
    // I have to be able to inject a fake CoreDataStack.
    // So what functions do I need.

    // This object should NOT know what to do with ManagedObject Context

    // The coredata stack should know what to do with a managed object context.

    //func getReadOnlyContext()
    func fetchThis(request: NSFetchRequest<NSFetchRequestResult>) -> NSFetchedResultsController<NSFetchRequestResult>
}















