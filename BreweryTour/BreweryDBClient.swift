//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import Alamofire
import CoreData


class BreweryDBClient {
    
    // MARK: Enumerations
    
    internal enum APIQueryOutputTypes {
        case BeersByStyleID
        case Styles
        case Breweries
        case BeersByBreweryID
        case Brewery
    }
    
    
    // MARK: Variables
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    
    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> BreweryDBClient {
        struct Singleton {
            static var sharedInstance = BreweryDBClient()
        }
        return Singleton.sharedInstance
    }
    
    
    
    // MARK: Functions

    internal func downloadBreweryBy(name: String, completion: @escaping (_ success: Bool) -> Void ) {
        let theOutputType = APIQueryOutputTypes.Breweries
        let methodParameters  = [
            "name" : "*\(name)*" as AnyObject,
            Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject//,
            //Constants.BreweryParameterKeys.HasImages : "Y" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: theOutputType,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    print("failed \(response.request?.url)")
                    completion(false)
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    print("Invalid tag informatiion")
                    completion(false)
                    return
                }
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  nil,
                           outputType: theOutputType,
                           completion: completion)
                return
        }
    }
    
    
    // Downloads all breweries
    internal func downloadAllBreweries(isOrganic : Bool , completion: @escaping (_ success: Bool) -> Void ) {
        var methodParameters = [String:AnyObject]()
        if isOrganic {
            methodParameters  = [
                Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
                Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
                Constants.BreweryParameterKeys.Organic : "Y" as AnyObject,
                Constants.BreweryParameterKeys.HasImages : "Y" as AnyObject
            ]
        } else {
            methodParameters  = [
                Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
                "name" : "*brewery*" as AnyObject,
                Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject//,
                //Constants.BreweryParameterKeys.HasImages : "Y" as AnyObject
            ]
        }
        
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Breweries,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    print("failed \(response.request?.url)")
                    completion(false)
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    print("Invalid tag informatiion")
                    completion(false)
                    return
                }
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  nil,
                           outputType: APIQueryOutputTypes.Breweries,
                           completion: completion)
                return
        }
    }
    
    
    // Downloads Beer Styles
    internal func downloadBeerStyles(completionHandler: @escaping (_ success: Bool) -> Void ) {
        let methodParameter : [String:AnyObject] = [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Styles,
                                                        querySpecificID: nil,
                                                        parameters: methodParameter)
        Alamofire.request(outputURL.absoluteString!).responseJSON(){ response in
            guard response.result.isSuccess else {
                completionHandler(false)
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                print("Invalid tag informatiion")
                completionHandler(false)
                return
            }
            self.parse(response: responseJSON as NSDictionary,
                       querySpecificID:  nil,
                       outputType: APIQueryOutputTypes.Styles,
                       completion: completionHandler)
            return
        }
    }
    
    
    // Download all beers from a Brewery
    // GET: /brewery/:breweryId/beers
    internal func downloadBeersBy(brewery: Brewery,
                                  completionHandler: @escaping ( _ success: Bool ) -> Void ) {
        let consistentOutput = APIQueryOutputTypes.BeersByBreweryID
        let methodParameter : [String:AnyObject] =
            [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
             ]
        let outputURL : NSURL = createURLFromParameters(queryType: consistentOutput,
                                                        querySpecificID: brewery.id,
                                                        parameters: methodParameter)
        Alamofire.request(outputURL.absoluteString!).responseJSON(){ response in
            guard response.result.isSuccess else {
                completionHandler(false)
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                print("Invalid tag informatiion")
                completionHandler(false)
                return
            }
            self.parse(response: responseJSON as NSDictionary,
                       querySpecificID : brewery.id,
                       outputType: consistentOutput,
                       completion: completionHandler)
            return
        }
    }
    
    
    // Query for breweries that offer a certain style.
    internal func downloadBreweriesBy(styleID : String, isOrganic : Bool , completion: @escaping (_ success: Bool)-> Void ) {
        let methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.Organic : (isOrganic ? "Y" : "N") as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    print("failed \(response.request?.url)")
                    completion(false)
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    print("Invalid tag informatiion")
                    completion(false)
                    return
                }
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  styleID,
                           outputType: APIQueryOutputTypes.BeersByStyleID,
                           completion: completion)
                return
        }
    }
    
    
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       outputType: APIQueryOutputTypes,
                       completion: @escaping (_ success :  Bool)-> Void)  {
        
        // Clear out previous query from background ManagedObjectContext
        // This will delete both Beers and Breweries but not styles
        // We currently only save favorites to disk
        //        for i in (coreDataStack?.backgroundContext.registeredObjects)! {
        //            coreDataStack?.backgroundContext.delete(i)
        //        }
        //        do {
        //            try coreDataStack?.backgroundContext.save()
        //        } catch {
        //            // Fail because we couldn't delete the old data.
        //            completion(false)
        //            return
        //        }
        
        // Process every query type accordingly
        switch outputType {
            
        // Beers query
        case APIQueryOutputTypes.BeersByStyleID:
            // TODO Remove all the breweries that are currently being drawn?
            
            // The Keys in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            // Extracting beer data array of dictionaries
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data \n \(response)")
                completion(false)
                // No beers were returned, which can happen
                return
            }
            
            for beer in beerArray {
                print("---------------------NextBeer---------------------")
                // TODO This beer could be in the database already
                // Skip this beer
                // Just because this beer is in the database doesn't mean that this brewery is in the database.
                // Because the user could have deleted the brewery.
                let b = getBeerByID(id: beer["id"] as! String, context: (coreDataStack?.persistingContext)!)
                if b != nil {
                    print("This beer is already in the database") // If I skip here how to do i mark the breweries for display?
                    continue
                }
                // Every beer is a dictionary; that also has an array of brewery information
                
                // Create the coredata object for each beer
                // which will include name, description, availability, brewery name, styleID
                
                let beerid : String? = beer["id"] as? String
                let beername : String? = beer["name"] as? String ?? ""
                let beerdescription : String? = (beer["description"] as? String) ?? ""
                var beeravailable : String? = nil
                if let interimAvail = beer["available"] {
                    let verbage = interimAvail["description"] as? String ?? "No Information Provided"
                    beeravailable = verbage
                }
                // This beer has no brewery information, continue with the next beer
                guard let breweriesArray = beer["breweries"]  else {
                    print("No breweries here move on")
                    continue
                }
                for brewery in breweriesArray as! Array<AnyObject> {
                    //print("Another brewery encoutered")
                    let breweryDict = brewery as! [String : AnyObject]
                    
                    guard let locationInfo = breweryDict["locations"] as? NSArray else {
                        continue
                    }
                    
                    // TODO Check other information that may be useful for customer
                    let locDic = locationInfo[0] as! [String : AnyObject]
                    // We can't visit a brewery if it's not open to the public
                    if locDic["openToPublic"] as! String == "Y" &&
                        locDic["latitude"]?.description != "" &&
                        locDic["longitude"]?.description != "" &&
                        locDic["longitude"] != nil &&
                        locDic["latitude"] != nil   {
                        
                        // Check to make sure the brewery is not already in the database
                        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
                        request.sortDescriptors = []
                        request.predicate = NSPredicate(format: "id == %@",locDic["id"] as! CVarArg)
                        let context = coreDataStack?.persistingContext
                        var isBreweryInDB : Bool = false
                        var breweries : [Brewery] = [Brewery]()
                        do {
                            breweries = try (context?.fetch(request))! as [Brewery]
                            // This brewery is in the database already
                            if breweries.count > 0 { isBreweryInDB = true }
                        } catch {
                            fatalError()
                        }
                        var newBrewery : Brewery!
                        if !isBreweryInDB { // Create a brewery object
                             newBrewery = Brewery(inName: breweryDict["name"] as! String,
                                                     latitude: locDic["latitude"]?.description,
                                                     longitude: locDic["longitude"]?.description,
                                                     url: locDic["website"] as! String?,
                                                     open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                                     id: locDic["id"]?.description,
                                                     context: (coreDataStack?.persistingContext)!)
                            //savePersitent()
                            breweries.append(newBrewery) // Brewery object should be empty
                        } else { print("Brewery is in database skipping Brewery creation") }
                        
                        // Creating beer
                        print("Creating ")
                        // Just because this beer is in the database doesn't mean that this brewery is in the database.
                        var thisBeer = getBeerByID(id: beer["id"] as! String, context: (coreDataStack?.persistingContext)!)
                        if thisBeer == nil {
                            thisBeer = Beer(id: beerid!, name: beername ?? "", beerDescription: beerdescription ?? "", availability: beeravailable ?? "", context: (coreDataStack?.persistingContext!)!)
                        }
                        thisBeer?.breweryID = breweries[0].id
                        thisBeer?.brewer = newBrewery
                        thisBeer?.styleID = querySpecificID
                        
                        // TODO Save Icons for Beer
                        saveBeerImageIfPossible(imagesDict: beer["labels"] as AnyObject, beer: thisBeer!)
                        // Save images for the brewery
                        saveBreweryImagesIfPossible(input: breweryDict["images"], inputBrewery: newBrewery)
                        
                        print("----->Finished adding a new beer and a brewery")
                        print("This many objects need updating \(coreDataStack?.persistingContext.updatedObjects)")
                        print("This many objects need inserting \(coreDataStack?.persistingContext.insertedObjects)")
                        //savePersitent()
                        print("This many objects were updating \(coreDataStack?.persistingContext.updatedObjects)")
                        print("This many objects were inserting \(coreDataStack?.persistingContext.insertedObjects)")

                    } else {
                        print("Closed to the public")
                        print("Location looks like \(locationInfo)")
                        print("latitude: \(locDic["latitude"]) longitude: \(locDic["longitude"])")
                    }
                }
            }
            print("Attempting to save all beers and breweries")
            do {
                try coreDataStack?.persistingContext.save()
                completion(true)
                return
            } catch let error {
                completion(false)
                fatalError("Saving background error \(error)")
                return
            }
            
            break
            
            
        case .Styles:
            // Styles are saved on the persistingContext because they don't change often.
            // We must have data to process
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else {
                print("Failed to convert")
                return
            }
            // Check to see if the style is already in coredata then skip, else add
            let request = NSFetchRequest<Style>(entityName: "Style")
            request.sortDescriptors = []
            print("Style array has this many entries \(styleArrayOfDict.count)")
            for aStyle in styleArrayOfDict {
                print("astyle \(aStyle)")
                let localId = aStyle["id"]?.stringValue
                let localName = aStyle["name"]
                do {
                    request.predicate = NSPredicate(format: "id = %@", localId!)
                    let results = try coreDataStack?.persistingContext.fetch(request)
                    if (results?.count)! > 0 {
                        print("This style is already in the database.")
                        continue
                    }
                } catch {
                    fatalError()
                }
                
                Style(id: localId!, name: localName! as! String, context: (coreDataStack?.persistingContext)!)
            }
            
            // Save beer styles to disk
            do {
                try coreDataStack?.persistingContext.save()
                completion(true)
                return
            } catch {
                completion(false)
                fatalError("Error saving styles")
                return
            }
            return
            break
            
            
            
        case .Breweries:
            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                print("\(#function) \(#line):Unable to parse Brewery Failed to extract data, there was no data component")
                return
            }
            // These number of pages means we can pull in more breweries
            print("numberofpages:\(response["numberOfPages"]) results:\(response["totalResults"])")
            print("We are creating \(breweryArray.count) breweries")
            
            for breweryDict in breweryArray {
                // All conditions that prevent us from going to the brewery
                guard let locationInfo = breweryDict["locations"] as? NSArray
                    // Can't build a brewery location if no location exists
                    else { continue }
                guard let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                    let openToPublic = locDic["openToPublic"],
                    openToPublic as! String == "Y",
                    locDic["latitude"]?.description != "",
                    locDic["longitude"]?.description != "",
                    locDic["longitude"] != nil,
                    locDic["latitude"] != nil
                    else { continue }
                
                // Extract location information
                
                // Create the brewery object
                
                // Don't repeat breweries in the database
                let brewery = getBreweryByID(id: locDic["id"] as! String, context: (coreDataStack?.persistingContext)!)
                guard brewery == nil else {
                    continue
                }
                
                let thisBrewery : Brewery = Brewery(inName: breweryDict["name"] as! String,
                                                    latitude: locDic["latitude"]?.description,
                                                    longitude: locDic["longitude"]?.description,
                                                    url: locDic["website"] as! String?,
                                                    open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                                    id: locDic["id"]?.description,
                                                    context: (coreDataStack?.persistingContext)!)
                print("creatd brewery object \(thisBrewery.objectID)")
                // Capture and download images for later use
                guard let imagesDict : [String:AnyObject] = breweryDict["images"] as? [String:AnyObject],
                    let imageURL : String = imagesDict["medium"] as! String?
                    else {
                        // We loaded this Brewery already but it has no images
                        // Skip image capture and continue to load breweries
                        continue
                }
                // Capture images asynchronously
                let queue = DispatchQueue(label: "Images")
                queue.async(qos: .utility) {
                    print("Getting images in background")
                    self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!,
                                                           forBrewery: thisBrewery,
                                                           updateManagedObjectID: thisBrewery.objectID)
                }
                
            }// Go back to the breweryArray and save another brewery
            
            // Save all the Breweries in background context to disk
            do {
                try coreDataStack?.persistingContext.save()
                print("Brewery Saved to Persisting context")
                completion(true)
                return
            } catch let error {
                completion(false)
                fatalError("Saving background error \(error)")
                return
            }
            break
            
            
        case .Brewery:
            guard let brewery = response["data"] as? [[String:AnyObject]] else {
                print("\(#function) \(#line):Unable to parse Brewery Failed to extract data, there was no data component")
                return
            }
            let breweryDict = brewery[0]
            
            // Brewery stub to populate
            var thisBrewery : Brewery!
            
            guard let locationInfo = breweryDict["locations"] as? NSArray else {
                // Can't build a brewery location if no location exists
                return
            }
            
            // Extract location information
            let locDic = locationInfo[0] as! [String : AnyObject]
            
            // We can't visit a brewery if it's not open to the public
            if locDic["openToPublic"] as! String == "Y" &&
                locDic["latitude"]?.description != "" &&
                locDic["longitude"]?.description != "" &&
                locDic["longitude"] != nil &&
                locDic["latitude"] != nil   {
                // Create the brewery object
                thisBrewery = Brewery(inName: breweryDict["name"] as! String,
                                      latitude: locDic["latitude"]?.description,
                                      longitude: locDic["longitude"]?.description,
                                      url: locDic["website"] as! String?,
                                      open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                      id: locDic["id"]?.description,
                                      context: (coreDataStack?.persistingContext)!)
                // Capture and download images for later use
                print("brewery created from brewery name search\(#line)")
                if let imagesDict : [String:AnyObject] = breweryDict["images"] as? [String:AnyObject],
                    let imageURL : String = imagesDict["medium"] as! String? {
                    let queue = DispatchQueue(label: "Images")
                    queue.async(qos: .utility) {
                        print("Getting brewery images in background")
                        self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!,
                                                               forBrewery: thisBrewery,
                                                               updateManagedObjectID: thisBrewery.objectID)
                        
                    }
                }
            }
            // Save the Brewery in background context
            do {
                try coreDataStack?.persistingContext.save()
                print("brewery save to persisting context")
            } catch let error {
                fatalError("Saving background error \(error)")
            }
            break
            
            
        case .BeersByBreweryID:
            // The Keys in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            // Extracting beer data array of dictionaries
            print("Capturing Beers By Brewery")
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data")
                completion(false)
                return
            }
            print("There are \(beerArray.count) beers pulled back from BreweryDB querys")
            for beer in beerArray {
                print("---------------------NextBeer---------------------")
                // Every beer is a dictionary; that also has an array of brewery information
                
                // Create the coredata object for each beer
                // which will include name, description, availability, brewery name, styleID
                
                // TODO before we go any further if  we already have this beer get out
                // guard
                
                let id : String? = beer["id"] as? String
                let name : String? = beer["name"] as? String ?? ""
                let description : String? = (beer["description"] as? String) ?? ""
                var available : String? = nil
                if let interimAvail = beer["available"] {
                    let verbage = interimAvail["description"] as? String ?? "No Information Provided"
                    available = verbage
                }
                
                // TODO test to see if beer is already in context
                let dbBeer = getBeerByID(id: id!, context: (coreDataStack?.persistingContext)!)
                guard dbBeer == nil else {
                    print("Encountered a beer of this type already skipping creation")
                    continue
                }
                
                let thisBeer = Beer(id: id!, name: name ?? "", beerDescription: description ?? "", availability: available ?? "", context: (coreDataStack?.persistingContext!)!)
                
                thisBeer.brewer = getBreweryByID(id: querySpecificID!, context: (coreDataStack?.persistingContext)!)
                
                thisBeer.breweryID = thisBeer.brewer?.id
                print("----->A beer added by breweryID \(thisBeer.brewer?.id) \(thisBeer.breweryID)")
                
                do {
                    try coreDataStack?.persistingContext.save()
                    completion(true)
                    return
                } catch let error {
                    completion(false)
                    fatalError("Saving background error \(error)")
                }
                
                // TODO Save Icons for display
                if let images = beer["labels"] as? [String : AnyObject],
                    //let icon = images["icon"] as! String?,
                    let medium = images["medium"] as! String?  {
                    thisBeer.imageUrl = medium
                    let queue = DispatchQueue(label: "Images")
                    print("Prior to getting image")
                    queue.async(qos: .utility) {
                        print("Getting beer label images in background")
                        self.downloadImageToCoreData(aturl: NSURL(string: thisBeer.imageUrl!)!, forBeer: thisBeer, updateManagedObjectID: thisBeer.objectID)
                    }
                }
                
            }
            break
        }
    }
    
    
    func saveBeerImageIfPossible(imagesDict: AnyObject , beer: Beer){
        if let images : [String:AnyObject] = imagesDict as? [String:AnyObject],
            let medium = images["medium"] as! String?  {
            beer.imageUrl = medium
            let queue = DispatchQueue(label: "Images")
            print("Prior to getting image")
            queue.async(qos: .utility) {
                print("Getting images in background")
                self.downloadImageToCoreData(aturl: NSURL(string: beer.imageUrl!)!, forBeer: beer, updateManagedObjectID: beer.objectID)
            }
        }
    }
    
    
    func saveBreweryImagesIfPossible(input: AnyObject?, inputBrewery : Brewery?) {
        if let imagesDict : [String:AnyObject] = input as? [String:AnyObject],
            let imageURL : String = imagesDict["icon"] as! String?,
            let targetBrewery = inputBrewery {
            let queue = DispatchQueue(label: "Images")
            queue.async(qos: .utility) {
                print("Getting images in background")
                self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!, forBrewery: targetBrewery, updateManagedObjectID: targetBrewery.objectID)
            }
        }
    }
    
    
    func getBreweryByID(id : String, context : NSManagedObjectContext) -> Brewery? {
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [id])
        do {
            if let brewery : [Brewery] = try context.fetch(request){
                //This type is in the database
                guard brewery.count > 0 else {
                    return nil}
                return brewery[0]
            }
        } catch {
            fatalError()
        }
        return nil
    }
    
    
    
    func getBeerByID(id: String, context: NSManagedObjectContext) -> Beer? {
        print("Attempting to get beer \(id)")
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
//        do {
//            let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: (coreDataStack?.persistingContext)!, sectionNameKeyPath: nil, cacheName: nil)
//            try frc.performFetch()
//            for i in frc.fetchedObjects! {
//                let b = i as Beer
//                if b.id == id {
//                    print("found it")
//                } else {
//                    print(b.id)
//                }
//            }
//        } catch {
//            
//        }
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [id])

        do {
            if let beer : [Beer] = try context.fetch(request){
                //This type is in the database
                guard beer.count > 0 else {
                    return nil}
                return beer[0]
            }
        } catch {
            fatalError()
        }
        return nil
    }
    
    
    
    func isElementInDatabase(entityType: String,
                             id: String,
                             context: NSManagedObjectContext ) -> Bool {
        // Check to make sure we are not already in the database
        let request : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityType)
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id == \(id)")
        do {
            let types : [NSFetchRequestResult] = try context.fetch(request)
            //This type is in the database
            return types.count > 0
        } catch {
            fatalError()
        }
        return false
    }
    
    
    // Download images in the background then update Coredata when complete
    internal func downloadImageToCoreData( aturl: NSURL,
                                           forBeer: Beer,
                                           updateManagedObjectID: NSManagedObjectID) {
        let session = URLSession.shared
        let task = session.dataTask(with: aturl as URL){
            (data, response, error) -> Void in
            if error == nil {
                if data == nil {
                    return
                }
                self.coreDataStack!.persistingContext.performAndWait(){
                    let beerForUpdate = self.coreDataStack!.persistingContext.object(with: updateManagedObjectID) as! Beer
                    let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                    beerForUpdate.image = outputData
                    do {
                        try self.coreDataStack!.persistingContext.save()
                        print("Beer Imaged saved for beer \(forBeer.beerName)")
                    }
                    catch {
                        return
                    }
                }
            }
        }
        task.resume()
    }
    
    
    // Download images in the background for a brewery
    internal func downloadImageToCoreDataForBrewery( aturl: NSURL,
                                                     forBrewery: Brewery,
                                                     updateManagedObjectID: NSManagedObjectID) {
        let session = URLSession.shared
        let task = session.dataTask(with: aturl as URL){
            (data, response, error) -> Void in
            if error == nil {
                if data == nil {
                    return
                }
                self.coreDataStack!.persistingContext.performAndWait(){
                    let breweryForUpdate = self.coreDataStack!.persistingContext.object(with: updateManagedObjectID) as! Brewery
                    let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                    breweryForUpdate.image = outputData
                    do {
                        try self.coreDataStack!.persistingContext.save()
                        print("Attention Brewery Imaged saved for brewery \(forBrewery.name)")
                    }
                    catch {
                        return
                    }
                }
            }
        }
        task.resume()
    }
    
    private func savePersitent(){
        do {
            try coreDataStack?.persistingContext.save()
        } catch let error {
            fatalError("Saving persistent error \(error)")
        }
    }
    
    private func createURLFromParameters(queryType: APIQueryOutputTypes,
                                         querySpecificID: String?,
                                         parameters: [String:AnyObject]) -> NSURL {
        // The url currently takes the form of
        // "http://api.brewerydb.com/v2/beers?key=\(Constants.BreweryParameterValues.APIKey)&format=json&isOrganic=Y&styleId=1&withBreweries=Y")
        let components = NSURLComponents()
        components.scheme = Constants.BreweryDB.APIScheme
        components.host = Constants.BreweryDB.APIHost
        
        switch queryType {
        case .BeersByStyleID:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Beers
            break
        case .Styles:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Styles
            break
        case .Brewery:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Breweries
            break
        case .Breweries:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Breweries
            break
        case .BeersByBreweryID:
            // GET: /brewery/:breweryId/beers
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Brewery + "/" +
                querySpecificID! + "/" + Constants.BreweryDB.Methods.Beers
        default:
            break
        }
        
        
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        
        
        // Build the other parameters
        for (key, value) in parameters {
            print(key,value)
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem as URLQueryItem)
        }
        
        // Add the API Key - QueryItem
        let queryItem : URLQueryItem = NSURLQueryItem(name: Constants.BreweryParameterKeys.Key, value: Constants.BreweryParameterValues.APIKey) as URLQueryItem
        components.queryItems?.append(queryItem)
        
        print("Calling url \(components.url)")
        return components.url! as NSURL
    }
}


extension BreweryDBClient {
    
    struct Constants {
        struct BreweryDB {
            static let APIScheme = "http"
            static let APIHost = "api.brewerydb.com"
            static let APIPath = "/v2/"
            struct Methods {
                static let Beers = "beers"
                static let Breweries = "breweries"
                static let Brewery = "brewery"
                static let Styles = "styles"
                static let Beer = "beer"
            }
        }
        
        struct BreweryParameterKeys {
            static let Key = "key"
            static let Format = "format"
            static let Organic = "isOrganic"
            static let StyleID = "styleId"
            static let WithBreweries = "withBreweries"
            static let HasImages = "hasImages"
            static let WithLocations = "withLocations"
        }
        
        struct BreweryParameterValues {
            static let APIKey = "8e63b90f589c3b3f2001c5e396f5d300"
            static let FormatJSON = "json"
        }
        
        struct BreweryLocation {
            var latitude : String
            var longitude : String
        }
    }
}
