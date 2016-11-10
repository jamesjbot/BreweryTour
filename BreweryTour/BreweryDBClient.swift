//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the api driver, that makes all the requests to the breweryDB
 **/

import Foundation
import Alamofire
import CoreData


class BreweryDBClient {
    
    // MARK: Enumerations
    
    internal enum APIQueryOutputTypes {
        case BeersByName
        case BeersByStyleID
        case Styles
        case Breweries
        case BeersByBreweryID
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
    
    // Downloads Beer Styles
    internal func downloadBeerStyles(completionHandler: @escaping (_ success: Bool,_ msg: String?) -> Void ) {
        let methodParameter : [String:AnyObject] = [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Styles,
                                                        querySpecificID: nil,
                                                        parameters: methodParameter)
        Alamofire.request(outputURL.absoluteString!).responseJSON(){ response in
            guard response.result.isSuccess else {
                completionHandler(false,"Failed Request \(#line) \(#function)")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completionHandler(false, "Failed Request \(#line) \(#function)")
                return
            }
            
            // Debugging code
            guard let numberOfPages = responseJSON["numberOfPages"] as! Int? else {
                //completion(false, "No results")
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
                                  completionHandler: @escaping ( _ success: Bool, _ msg: String? ) -> Void ) {
        let consistentOutput = APIQueryOutputTypes.BeersByBreweryID
        let methodParameter : [String:AnyObject] =
            [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
             ]
        let outputURL : NSURL = createURLFromParameters(queryType: consistentOutput,
                                                        querySpecificID: brewery.id,
                                                        parameters: methodParameter)
        
        // This is an async call
        Alamofire.request(outputURL.absoluteString!).responseJSON(){
            response in
            guard response.result.isSuccess else {
                completionHandler(false, "Failed Request \(#line) \(#function)")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completionHandler(false,"Failed Request \(#line) \(#function)")
                return
            }
            
            // query is brewery/breweryID/beers
            // Returned data is
            // "message":"READ ONLY MODE: Request Successful"
            // "data":[...]
            // "status":"success"
            
            self.parse(response: responseJSON as NSDictionary,
                       querySpecificID : brewery.id,
                       outputType: consistentOutput,
                       completion: completionHandler)
        }
        return
    }
    
    
    // Query for beers with a specific name
    internal func downloadBeersBy(name: String,
                                  completion: @escaping (_ success : Bool , _ msg : String? ) -> Void ) {
        let theOutputType = APIQueryOutputTypes.BeersByName
        var methodParameters  = [
            "name" : "*\(name)*" as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject,
            Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.Page : "1" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: theOutputType,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    completion(false, "Failed Request \(#line) \(#function)")
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed Request \(#line) \(#function)")
                    return
                }
                
                guard let numberOfPages = responseJSON["numberOfPages"] as! Int? else {
                    completion(false, "No results")
                    return
                }
                
                
                // Process first page
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  nil,
                           outputType: theOutputType,
                           completion: completion)
                
                // The follow block of code downloads all subsequesnt pages
                guard numberOfPages > 1 else {
                    completion(true, "Finished")
                    return
                }
                
                for i in 2...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
                                                                         querySpecificID: nil,
                                                                         parameters: methodParameters)
                    Alamofire.request(outputURL.absoluteString!)
                        .responseJSON {
                            response in
                            guard response.result.isSuccess else {
                                completion(false, "Failed Request \(#line) \(#function)")
                                return
                            }
                            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                                completion(false, "Failed Request \(#line) \(#function)")
                                return
                            }
                            self.parse(response: responseJSON as NSDictionary,
                                       querySpecificID:  nil,
                                       outputType: APIQueryOutputTypes.BeersByStyleID,
                                       completion: completion,
                                       finalPage: numberOfPages == i ? true : false)
                    }
                }
        }
    }
    
    
    // Query for breweries that offer a certain style.
    internal func downloadBeersAndBreweriesBy(styleID : String, isOrganic : Bool ,
                                              completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        var methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.Organic : (isOrganic ? "Y" : "N") as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject,
            Constants.BreweryParameterKeys.Page : "1" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    completion(false, "Failed Request \(#line) \(#function)")
                    
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed Request \(#line) \(#function)")
                    return
                }
                
                guard let numberOfPages = responseJSON["numberOfPages"] as! Int? else {
                    completion(false, "No results")
                    return
                }
                
                // p = page number
                // Process first page.
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  styleID,
                           outputType: APIQueryOutputTypes.BeersByStyleID,
                           completion: completion)
                
                // The following block of code downloads all subsequesnt pages
                guard numberOfPages > 1 else {
                    completion(true, "Finished")
                    return
                }
                print("Total pages \(numberOfPages)")
                
                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                
                for i in 2...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
                                                                         querySpecificID: nil,
                                                                         parameters: methodParameters)
                    group.enter()
                    queue.async(group: group) {
                        Alamofire.request(outputURL.absoluteString!)
                            .responseJSON {
                                response in
                                guard response.result.isSuccess else {
                                    completion(false, "Failed Request \(#line) \(#function)")
                                    
                                    return
                                }
                                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                                    completion(false, "Failed Request \(#line) \(#function)")
                                    return
                                }
                                
                                self.parse(response: responseJSON as NSDictionary,
                                           querySpecificID:  styleID,
                                           outputType: APIQueryOutputTypes.BeersByStyleID,
                                           completion: completion,
                                           finalPage: numberOfPages == i ? true : false)
                                print("page# \(i)")
                                group.leave()
                        } //Outside alamo but inside async
                    } //Outside queue.async
                }  // Outside for loop
                
                group.notify(queue: queue) {
                    completion(true, "All Pages Processed")
                }
        }
        return
    }
    
    
    // Query for breweries with a specific name
    internal func downloadBreweryBy(name: String, completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        let theOutputType = APIQueryOutputTypes.Breweries
        var methodParameters  = [
            "name" : "*\(name)*" as AnyObject,
            Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.Page : "1" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: theOutputType,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON {
                response in
                guard response.result.isSuccess else {
                    completion(false, "Failed Request \(#line) \(#function)")
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed Request \(#line) \(#function)")
                    return
                }
                
                guard let numberOfPages = responseJSON["numberOfPages"] as! Int? else {
                    completion(false, "No results")
                    return
                }
                
                
                // Process subsequent records
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  nil,
                           outputType: theOutputType,
                           completion: completion)
                // The following block of code downloads all subsequesnt pages
                guard numberOfPages > 1 else {
                    completion(true, "Finished")
                    return
                }
                
                print("Total pages \(numberOfPages)")
                
                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                print("Total pages \(numberOfPages)")
                for i in 2...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
                                                                         querySpecificID: nil,
                                                                         parameters: methodParameters)
                    group.enter()
                    queue.async(group: group) {
                        Alamofire.request(outputURL.absoluteString!)
                            .responseJSON {
                                response in
                                guard response.result.isSuccess else {
                                    completion(false, "Failed Request \(#line) \(#function)")
                                    
                                    return
                                }
                                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                                    completion(false, "Failed Request \(#line) \(#function)")
                                    return
                                }
                                self.parse(response: responseJSON as NSDictionary,
                                           querySpecificID:  nil,
                                           outputType: APIQueryOutputTypes.BeersByStyleID,
                                           completion: completion,
                                           finalPage: numberOfPages == i ? true : false)
                                print("page# \(i)")
                                group.leave()
                        }
                    }
                }
                group.notify(queue: queue) {
                    completion(true, "All Pages Processed")
                }
        }
        
        return
    }
    
    
    // Parse results into objects
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       outputType: APIQueryOutputTypes,
                       completion: (( (_ success :  Bool, _ msg: String?) -> Void )?),
                       finalPage: Bool = false){
        
        // Process every query type accordingly
        switch outputType {
            
        // Beers query
        case APIQueryOutputTypes.BeersByStyleID:
            // No beer data was returned which can happen
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "Failed Request \(#line) \(#function)")
                return
            }
            createBeerLoop: for (i,beer) in beerArray.enumerated() {
                // Check to see if this beer is in the database already, and skip if so
                guard getBeerByID(id: beer["id"] as! String, context: (coreDataStack?.persistingContext)!) == nil else {
                    continue createBeerLoop
                }
                // This beer has no brewery information, continue with the next beer
                guard let breweriesArray = beer["breweries"]  else {
                    continue createBeerLoop
                }
                breweryLoop: for brewery in breweriesArray as! Array<AnyObject> {
                    let breweryDict = brewery as? [String : AnyObject]
                    // There is no location info to display on the map.
                    guard let locationInfo = breweryDict?["locations"] as? NSArray else {
                        continue createBeerLoop
                    }
                    // We can't visit a brewery if it's not open to the public or we don't have coordinates
                    guard let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                        locDic["openToPublic"] as! String == "Y" &&
                            locDic["longitude"] != nil && locDic["latitude"] != nil else {
                                continue createBeerLoop
                    }
                    // Sometimes the breweries have no name, making it useless
                    guard breweryDict?["name"] != nil else {
                        // "Missing brewery name \(#line)"
                        continue breweryLoop
                    }
                    // Check to make sure the brewery is not already in the database
                    var dbBrewery : Brewery! = getBreweryByID(id: locDic["id"] as! String, context: (coreDataStack?.persistingContext)!)
                    if dbBrewery == nil { // Create a brewery object when needed.
                        dbBrewery = createBreweryObject(breweryDict: breweryDict!, locationDict: locDic)
                    }
                    let thisBeer = createBeerObject(beer: beer)
                    setBeerBrewerData(beer: thisBeer, breweryID: dbBrewery.id!, completion: completion!)
                    // Save Icons for Beer
                    saveBeerImageIfPossible(beerDict: beer as AnyObject, beer: thisBeer)
                    // Save images for the brewery
                    saveBreweryImagesIfPossible(input: breweryDict?["images"], inputBrewery: dbBrewery)
                }
            } // end of beer loop
            if finalPage == false {
                completion!(true, "Success")
            }
            break
            
        case .Styles:
            // Styles are saved on the persistingContext because they don't change often.
            // We must have data to process
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "No styles data" )
                return
            }
            // Check to see if the style is already in coredata then skip, else add
            let request = NSFetchRequest<Style>(entityName: "Style")
            request.sortDescriptors = []
            for aStyle in styleArrayOfDict {
                let localId = aStyle["id"]?.stringValue
                let localName = aStyle["name"]
                do {
                    request.predicate = NSPredicate(format: "id = %@", localId!)
                    let results = try coreDataStack?.persistingContext.fetch(request)
                    if (results?.count)! > 0 {
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
                completion!(true, "Success")
                return
            } catch {
                completion!(false, "Failed Request \(#line) \(#function)")
                return
            }
            return
            break
            
            
        case .Breweries:
            // The number of pages means we can pull in more breweries
            guard let pagesOfResult = response["numberOfPages"] as? Int else {
                completion!(false, "No results returned")
                return
            }
            
            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                //Unable to parse Brewery Failed to extract data, there was no data component
                completion!(false, "Network error please try again")
                return
            }
            
            breweryLoop: for breweryDict in breweryArray {
                // Can't build a brewery location if no location exist
                guard let locationInfo = breweryDict["locations"] as? NSArray
                    else {
                        continue
                }
                guard let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                    let openToPublic = locDic["openToPublic"],
                    openToPublic as! String == "Y",
                    locDic["longitude"] != nil,
                    locDic["latitude"] != nil
                    else {
                        continue breweryLoop
                }
                // Don't repeat breweries in the database
                var thisbrewery = getBreweryByID(id: locDic["id"] as! String, context: (coreDataStack?.persistingContext)!)
                guard thisbrewery == nil else {
                    continue
                }
                thisbrewery = createBreweryObject(breweryDict: breweryDict,
                                                  locationDict: locDic)
                // Capture images asynchronously
                saveBreweryImagesIfPossible(input: breweryDict["images"],
                                            inputBrewery: thisbrewery)
                
            }// Go back to the breweryArray and save another brewery
            // TODO Work on saving these values.
            // Save all the Breweries in background context to disk
            //            do {
            //                try coreDataStack?.persistingContext.save()
            //                print("Brewery Saved to Persisting context")
            //                completion!(true, "Success")
            //                return
            //            } catch {
            //                completion!(false, "Failed Request \(#line) \(#function)")
            //                return
            //            }
            if finalPage == false {
                completion!(true, "Success")
            } else {
                completion!(true, "Final Page")
            }
            break
            
        case .BeersByName:
            // The number of pages means we can pull in more breweries
            guard let pagesOfResult = response["numberOfPages"] as? Int else {
                completion!(false, "No results returned")
                return
            }
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                // No beers were returned, which can happen
                completion!(false, "Failed Request \(#line) \(#function)")
                return
            }
            
            beerLoop: for beer in beerArray {
                print("---------------------NextBeer---------------------")
                // Creating beer
                // Check to see if this beer is in the database already
                var thisBeer = getBeerByID(id: beer["id"] as! String, context: (coreDataStack?.persistingContext)!)
                // If the beer is in the coredata skip adding it
                guard thisBeer == nil else {
                    continue beerLoop
                }
                // This beer has no brewery information, continue with the next beer
                guard let breweriesArray = beer["breweries"]  else {
                    continue beerLoop
                }
                
                breweryLoop: for brewery in breweriesArray as! Array<AnyObject> {
                    let breweryDict = brewery as! [String : AnyObject]
                    
                    guard let locationInfo = breweryDict["locations"] as? NSArray else {
                        continue breweryLoop
                    }
                    
                    let locDic = locationInfo[0] as! [String : AnyObject]
                    // We can't visit a brewery if it's not open to the public or we don't have coordinates
                    guard locDic["openToPublic"] as! String == "Y" &&
                        locDic["longitude"] != nil &&
                        locDic["latitude"] != nil else {
                            continue breweryLoop
                    }
                    
                    // Check to make sure the brewery is not already in the database
                    var newBrewery : Brewery!
                    newBrewery = getBreweryByID(id: locDic["id"] as! String, context: (coreDataStack?.persistingContext)!)
                    
                    if newBrewery == nil { // Create a brewery object
                        newBrewery = createBreweryObject(breweryDict: breweryDict,
                                                         locationDict: locDic)
                    }
                    
                    let thisBeer = createBeerObject(beer: beer)
                    // Set Brewery
                    setBeerBrewerData(beer: thisBeer,
                                      breweryID: newBrewery.id!,
                                      completion: completion!)
                    // Save Icons for Beer
                    saveBeerImageIfPossible(beerDict: beer as AnyObject, beer: thisBeer)
                    // Save images for the brewery
                    saveBreweryImagesIfPossible(input: breweryDict["images"], inputBrewery: newBrewery)
                    // Future Improvement.
                    // Currently datamodel cannot accomodate multple brewery locations for a beer
                    break
                } // End of For Brewery
                // This will save every beer
                
            } // end of beer loop
            if finalPage == false {
                completion!(true, "Success")
            } else {
                completion!(true, "Final Page")
            }
            break
            
        case .BeersByBreweryID:
            print("Capturing Beers By Brewery")
            
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                // Failed to extract data
                completion!(false, "Failed Request \(#line) \(#function)")
                return
            }
            
            for beer in beerArray {
                print("---------------------NextBeer---------------------")
                // Create the coredata object for each beer
                // Test to see if beer is already in context
                let id : String? = beer["id"] as? String
                let dbBeer = getBeerByID(id: id!, context: (coreDataStack?.persistingContext)!)
                guard dbBeer == nil else {
                    print("Encountered a beer of this type already skipping creation")
                    continue
                }
                let thisBeer = createBeerObject(beer: beer)
                
                setBeerBrewerData(beer: thisBeer,
                                  breweryID: querySpecificID!,
                                  completion: completion!)
                
                saveBeerImageIfPossible(beerDict: beer as AnyObject, beer: thisBeer)
            }
            break
        }
    }
    
    
    // This sets brewerid when brewerid is supplied
    // and save the brewery
    func setBeerBrewerData(beer thisBeer: Beer,
                           breweryID querySpecificID: String,
                           completion: (Bool,String) -> Void) {
        thisBeer.brewer = getBreweryByID(id: querySpecificID, context: (coreDataStack?.persistingContext)!)
        
        thisBeer.breweryID = thisBeer.brewer?.id
        //print("----->A beer added by breweryID \(thisBeer.brewer?.id) \(thisBeer.breweryID)")
        
        //        do {
        //            try coreDataStack?.persistingContext.save()
        //            completion(true, "Success")
        //            return
        //        } catch let error {
        //            completion(false, "Failed Request \(#line) \(#function)")
        //            fatalError("Saving background error \(error)")
        //        }
    }
    
    
    func createBeerObject(beer : [String:AnyObject] ) -> Beer {
        let id : String? = beer["id"] as? String
        let name : String? = beer["name"] as? String ?? ""
        let description : String? = (beer["description"] as? String) ?? ""
        var available : String? = nil
        let beerabv : String? = beer["abv"] as? String
        let beeribu : String? = beer["ibu"] as? String
        if let interimAvail = beer["available"] {
            available = interimAvail["description"] as? String ?? "No Information Provided"
        } else {
            available = "No Information Provided"
        }
        
        let thisBeer = Beer(id: id!, name: name!,
                            beerDescription: description!,
                            availability: available!,
                            context: (coreDataStack?.persistingContext!)!)
        thisBeer.styleID = beer["styleID"] as? String
        thisBeer.abv = beerabv ?? "Information N/A"
        thisBeer.ibu = beeribu ?? "Information N/A"
        return thisBeer
    }
    
    
    func createBreweryObject(breweryDict: [String:AnyObject], locationDict locDict:[String:AnyObject]) -> Brewery {
        return Brewery(inName: breweryDict["name"] as! String,
                       latitude: locDict["latitude"]?.description,
                       longitude: locDict["longitude"]?.description,
                       url: locDict["website"] as! String?,
                       open: (locDict["openToPublic"] as! String == "Y") ? true : false,
                       id: locDict["id"]?.description,
                       context: (coreDataStack?.persistingContext)!)
    }
    
    
    func saveBeerImageIfPossible(beerDict: AnyObject , beer: Beer){
        if let images : [String:AnyObject] = beerDict["labels"] as? [String:AnyObject],
            let medium = images["medium"] as! String?  {
            beer.imageUrl = medium
            let queue = DispatchQueue(label: "Images")
            //print("Prior to getting image")
            queue.async(qos: .utility) {
                //print("Getting images in background")
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
                //print("Getting images in background")
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
        //print("Attempting to get beer \(id)")
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [id])
        
        do {
            if let beer : [Beer] = try context.fetch(request) {
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
    
    
    
    //    func isElementInDatabase(entityType: String,
    //                             id: String,
    //                             context: NSManagedObjectContext ) -> Bool {
    //        // Check to make sure we are not already in the database
    //        let request : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityType)
    //        request.sortDescriptors = []
    //        request.predicate = NSPredicate(format: "id == \(id)")
    //        do {
    //            let types : [NSFetchRequestResult] = try context.fetch(request)
    //            //This type is in the database
    //            return types.count > 0
    //        } catch {
    //            fatalError()
    //        }
    //        return false
    //    }
    
    
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
                self.coreDataStack!.mainContext.performAndWait(){
                    let beerForUpdate = self.coreDataStack!.persistingContext.object(with: updateManagedObjectID) as! Beer
                    let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                    beerForUpdate.image = outputData
                    do {
                        try self.coreDataStack!.mainContext.save()
                        //print("Beer Imaged saved for beer \(forBeer.beerName)")
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
                self.coreDataStack!.mainContext.performAndWait(){
                    let breweryForUpdate = self.coreDataStack!.persistingContext.object(with: updateManagedObjectID) as! Brewery
                    let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                    breweryForUpdate.image = outputData
                    do {
                        try self.coreDataStack!.mainContext.save()
                        //print("Attention Brewery Imaged saved for brewery \(forBrewery.name)")
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
        case .BeersByName:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Beers
            break
        case .BeersByStyleID:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Beers
            break
        case .Styles:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Styles
            break
        case .Breweries:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Breweries
            break
        case .BeersByBreweryID:
            // GET: /brewery/:breweryId/beers
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Brewery + "/" +
                querySpecificID! + "/" + Constants.BreweryDB.Methods.Beers
        }
        
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        
        // Build the other parameters
        for (key, value) in parameters {
            //print(key,value)
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem as URLQueryItem)
        }
        
        // Finally Add the API Key - QueryItem
        let queryItem : URLQueryItem = NSURLQueryItem(name: Constants.BreweryParameterKeys.Key, value: Constants.BreweryParameterValues.APIKey) as URLQueryItem
        components.queryItems?.append(queryItem)
        
        print("\(components.url!)")
        return components.url! as NSURL
    }
}


