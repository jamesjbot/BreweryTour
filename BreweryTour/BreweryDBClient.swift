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
    
    // Download Breweries by *name*
    internal func downloadBreweryBy(name: String, completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
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
                    completion(false, "Failed request")
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed request")
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
//    internal func downloadAllBreweries(isOrganic : Bool , completion: @escaping (_ success: Bool) -> Void ) {
//        var methodParameters = [String:AnyObject]()
//        if isOrganic {
//            methodParameters  = [
//                Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
//                Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
//                Constants.BreweryParameterKeys.Organic : "Y" as AnyObject,
//                Constants.BreweryParameterKeys.HasImages : "Y" as AnyObject
//            ]
//        } else {
//            methodParameters  = [
//                Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
//                "name" : "*brewery*" as AnyObject,
//                Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject//,
//                //Constants.BreweryParameterKeys.HasImages : "Y" as AnyObject
//            ]
//        }
//        
//        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Breweries,
//                                                        querySpecificID: nil,
//                                                        parameters: methodParameters)
//        Alamofire.request(outputURL.absoluteString!)
//            .responseJSON {
//                response in
//                guard response.result.isSuccess else {
//                    print("failed \(response.request?.url)")
//                    completion(false)
//                    return
//                }
//                guard let responseJSON = response.result.value as? [String:AnyObject] else {
//                    print("Invalid tag informatiion")
//                    completion(false)
//                    return
//                }
//                self.parse(response: responseJSON as NSDictionary,
//                           querySpecificID:  nil,
//                           outputType: APIQueryOutputTypes.Breweries,
//                           completion: completion)
//                return
//        }
//    }
    
    
    // Downloads Beer Styles
    internal func downloadBeerStyles(completionHandler: @escaping (_ success: Bool,_ msg: String?) -> Void ) {
        let methodParameter : [String:AnyObject] = [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Styles,
                                                        querySpecificID: nil,
                                                        parameters: methodParameter)
        Alamofire.request(outputURL.absoluteString!).responseJSON(){ response in
            guard response.result.isSuccess else {
                completionHandler(false,"Failed Request")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completionHandler(false, "Failed Request")
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
        Alamofire.request(outputURL.absoluteString!).responseJSON(){ response in
            guard response.result.isSuccess else {
                completionHandler(false, "Failed Request")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completionHandler(false,"Failed Request")
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
    internal func downloadBreweriesBy(styleID : String, isOrganic : Bool ,
                                      completion: @escaping (_ success: Bool, _ msg: String?)-> Void ) {
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
                    completion(false, "Failed Request")

                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed Request")
                    return
                }
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  styleID,
                           outputType: APIQueryOutputTypes.BeersByStyleID,
                           completion: completion)
                return
        }
    }
    
    // Parse results into objects
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       outputType: APIQueryOutputTypes,
                       completion: @escaping (_ success :  Bool, _ msg: String?)-> Void)  {
        
        // Process every query type accordingly
        switch outputType {
            
        // Beers query
        case APIQueryOutputTypes.BeersByStyleID:
            
            // The Keys in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            // Extracting beer data array of dictionaries
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                completion(false, "Failed Request")
                // No beers were returned, which can happen
                return
            }
            
            beerLoop: for beer in beerArray {
                print("---------------------NextBeer---------------------")

                // Creating beer
                print("Check if beer needs to be created")
                // Check to see if this beer is in the database already
                var thisBeer = getBeerByID(id: beer["id"] as! String, context: (coreDataStack?.persistingContext)!)
                // If the beer is in the coredata skip adding it
                if thisBeer != nil {
                    continue beerLoop
                }
                // Every beer is a dictionary; that also has an array of brewery information
                
                // Create the coredata object for each beer
                // which will include name, description, availability, brewery name, styleID
                let beerid : String? = beer["id"] as? String
                let beername : String? = beer["name"] as? String ?? ""
                let beerdescription : String? = beer["description"] as? String
                let beeravailable : String? = beer["available"] as? String
                let beerabv : String? = beer["abv"] as? String
                let beeribu : String? = beer["ibu"] as? String
                // This beer has no brewery information, continue with the next beer
                guard let breweriesArray = beer["breweries"]  else {
                    continue beerLoop
                }
                
                for brewery in breweriesArray as! Array<AnyObject> {
                    let breweryDict = brewery as! [String : AnyObject]
                    
                    guard let locationInfo = breweryDict["locations"] as? NSArray else {
                        continue
                    }
                    
                    let locDic = locationInfo[0] as! [String : AnyObject]
                    // We can't visit a brewery if it's not open to the public or we don't have coordinates
                    assert(locDic["latitude"]?.description != "")
                    assert(locDic["longitude"]?.description != "")
                    assert(locDic["longitude"] != nil)
                    assert(locDic["latitude"] != nil)
                    guard locDic["openToPublic"] as! String == "Y" &&
                        locDic["latitude"]?.description != "" &&
                        locDic["longitude"]?.description != "" &&
                        locDic["longitude"] != nil &&
                        locDic["latitude"] != nil else {
                            continue beerLoop
                    }
                    
                    // Check to make sure the brewery is not already in the database
                    var newBrewery : Brewery!
                    newBrewery = getBreweryByID(id: locDic["id"] as! String, context: (coreDataStack?.persistingContext)!)
                    if newBrewery == nil { // Create a brewery object
                        newBrewery = Brewery(inName: breweryDict["name"] as! String,
                                             latitude: locDic["latitude"]?.description,
                                             longitude: locDic["longitude"]?.description,
                                             url: locDic["website"] as! String?,
                                             open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                             id: locDic["id"]?.description,
                                             context: (coreDataStack?.persistingContext)!)
                    } else { print("Brewery is in database skipping Brewery creation") }
                    
                    thisBeer = Beer(id: beerid!,
                                    name:beername ?? "Information N/A",
                                    beerDescription: beerdescription ?? "Information N/A",
                                    availability: beeravailable ?? "Information N/A",
                                    context: (coreDataStack?.persistingContext!)!)
                    thisBeer?.breweryID = newBrewery.id
                    thisBeer?.brewer = newBrewery
                    thisBeer?.styleID = querySpecificID
                    thisBeer?.abv = beerabv ?? "Information N/A"
                    thisBeer?.ibu = beeribu ?? "Information N/A"
                    // Save Icons for Beer
                    saveBeerImageIfPossible(imagesDict: beer["labels"] as AnyObject, beer: thisBeer!)
                    // Save images for the brewery
                    saveBreweryImagesIfPossible(input: breweryDict["images"], inputBrewery: newBrewery)
                    //savePersitent()
                } // End of For Brewery
                // This will save every beer
                
            } // end of beer loop
            completion(true, "Success")
            //            print("Attempting to save all beers and breweries")
            //            do {
            //                try coreDataStack?.persistingContext.save()
            //                completion(true)
            //                return
            //            } catch let error {
            //                completion(false)
            //                fatalError("Saving background error \(error)")
            //                return
            //            }
            
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
                completion(true, "Success")
                return
            } catch {
                completion(false, "Failed Request")
                fatalError("Error saving styles")
                return
            }
            return
            break
            
            
        case .Breweries:
            // The number of pages means we can pull in more breweries
            guard let pagesOfResult = response["numberOfPages"] as? Int else {
                completion(false, "No results returned")
                return
            }
            guard pagesOfResult == 1 else {
                completion(false, "Too many Breweries match, be more specific")
                return
            }
            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                //Unable to parse Brewery Failed to extract data, there was no data component
                completion(false, "Network error please try again")
                return
            }
            
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
                completion(true, "Success")
                return
            } catch let error {
                completion(false, "Failed Request")
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
            break
            
            
        case .BeersByBreweryID:
            // The Keys in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            // Extracting beer data array of dictionaries
            print("Capturing Beers By Brewery")
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data")
                completion(false, "Failed Request")

                return
            }
            for beer in beerArray {
                print("---------------------NextBeer---------------------")
                // Every beer is a dictionary; that also has an array of brewery information
                
                // Create the coredata object for each beer
                // which will include name, description, availability, brewery name, styleID
                
                let id : String? = beer["id"] as? String
                let name : String? = beer["name"] as? String ?? ""
                let description : String? = (beer["description"] as? String) ?? ""
                var available : String? = nil
                if let interimAvail = beer["available"] {
                    let verbage = interimAvail["description"] as? String ?? "No Information Provided"
                    available = verbage
                }
                
                // Test to see if beer is already in context
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
                    completion(true, "Success")
                    return
                } catch let error {
                    completion(false, "Failed Request")
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
        do {
            try coreDataStack?.persistingContext.save()
        } catch let error {
            fatalError("Saving persistent error \(error)")
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
