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
        case Beers
        case Styles
        case Breweries
        case BeersByABreweryID
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
    // TODO May not need this anymore
    // Purpose: get brewery data by it's id
    //    internal func getBreweryData(id: String){
    //        let methodParameters : [String:AnyObject] = ["id":id as AnyObject]
    //        let outputURL : NSURL = createURLFromParameters(queryType: .Brewery, parameters: methodParameters)
    //
    //    }
    internal func downloadBreweryBy(name: String, completion: @escaping (_ success: Bool) -> Void ) {
        let methodParameters  = [
            Constants.BreweryParameterKeys.WithLocations : "Y" as AnyObject,
            "name" : "*\(name)*" as AnyObject,
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject//,
            //Constants.BreweryParameterKeys.HasImages : "Y" as AnyObject
        ]
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
                           asQueryType: APIQueryOutputTypes.Breweries,
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
                           asQueryType: APIQueryOutputTypes.Breweries,
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
                       asQueryType: APIQueryOutputTypes.Styles,
                       completion: completionHandler)
            return
        }
    }
    
    
    // Download all beers from a Brewery
    // GET: /brewery/:breweryId/beers
    internal func downloadBeersBy(brewery: Brewery,
                                  completionHandler: @escaping ( _ success: Bool ) -> Void ) {
        let consistentOutput = APIQueryOutputTypes.BeersByABreweryID
        let methodParameter : [String:AnyObject] =
            [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
             ]
        let outputURL : NSURL = createURLFromParameters(queryType: consistentOutput,
                                                        querySpecificID: "4OBVPn",//brewery.id,
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
                       asQueryType: consistentOutput,
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
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Beers,
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
                           asQueryType: APIQueryOutputTypes.Beers,
                           completion: completion)
                return
        }
    }
    
    
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       asQueryType: APIQueryOutputTypes,
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
        switch asQueryType {
            
        // Beers query
        case APIQueryOutputTypes.Beers:
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
                let thisBeer = Beer(id: id!, name: name ?? "", beerDescription: description ?? "", availability: available ?? "", context: (coreDataStack?.backgroundContext!)!)
                
                // TODO Save Icons for display
                if let images = beer["labels"] as? [String : AnyObject],
                    //let icon = images["icon"] as! String?,
                    let medium = images["medium"] as! String?  {
                    thisBeer.imageUrl = medium
                    let queue = DispatchQueue(label: "Images")
                    print("Prior to getting image")
                    queue.async(qos: .utility) {
                        print("Getting images in background")
                        self.downloadImageToCoreData(aturl: NSURL(string: thisBeer.imageUrl!)!, forBeer: thisBeer, updateManagedObjectID: thisBeer.objectID)
                    }
                }
                
                // This beer has no brewery information, continue with the next beer
                guard let breweriesArray = beer["breweries"]  else {
                    print("No breweries here move on")
                    continue
                }
                for brewery in breweriesArray as! Array<AnyObject> {
                    //print("Another brewery encoutered")
                    // The brewery dictionary
                    let breweryDict = brewery as! NSDictionary
                    
                    guard let locationInfo = breweryDict["locations"] as? NSArray else {
                        continue
                    }
                    
                    // TODO Check other information that may be useful for customer
                    let locDic = locationInfo[0] as! [String : AnyObject]
                    // We can't visit a brewery if it's not open to the public
                    //print(locDic["latitude"])
                    //print(locDic["longitude"])
                    if locDic["openToPublic"] as! String == "Y" &&
                        locDic["latitude"]?.description != "" &&
                        locDic["longitude"]?.description != "" &&
                        locDic["longitude"] != nil &&
                        locDic["latitude"] != nil   {
                        //print("Here is a brewery for this beer \(breweryDict["name"] as! String)")
                        //                        breweryLocationsSet.insert(
                        //                            BreweryLocation(
                        //                                latitude: locDic["latitude"]?.description,
                        //                                longitude: locDic["longitude"]?.description,
                        //                                url: locDic["website"] as! String?,
                        //                                name: breweryDict["name"] as! String))
                        //        // Check to make sure we are not already in the database
                        //        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
                        //        request.sortDescriptors = []
                        //        request.predicate = NSPredicate(format: "id == \(inBrewery.id)")
                        //        do {
                        //            let breweries : [Brewery] = try context.fetch(request) as [Brewery]
                        //            // This brewery is in the database already
                        //            if breweries.count > 0 {return}
                        //        } catch {
                        //            fatalError()
                        //        }
                        let thisBrewery = Brewery(inName: breweryDict["name"] as! String,
                                                  latitude: locDic["latitude"]?.description,
                                                  longitude: locDic["longitude"]?.description,
                                                  url: locDic["website"] as! String?,
                                                  open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                                  id: locDic["id"]?.description,
                                                  context: (coreDataStack?.backgroundContext)!)
                        thisBrewery.mustDraw = true
                        if let imagesDict : [String:AnyObject] = breweryDict["images"] as? [String:AnyObject] {
                            if let imageURL : String = imagesDict["medium"] as! String? {
                                let queue = DispatchQueue(label: "Images")
                                queue.async(qos: .utility) {
                                    print("Getting images in background")
                                    self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!, forBrewery: thisBrewery, updateManagedObjectID: thisBrewery.objectID)
                                }
                            }
                        }
                        //print("Brewery object created \(locDic["id"])")
                        // Assign this brewery to this beer
                        thisBeer.brewer = thisBrewery
                        
                        //We might only create the beer if the brewery is open
                    } else {
                        print("Closed to the public")
                        print("Location looks like \(locationInfo)")
                        print("latitude: \(locDic["latitude"]) longitude: \(locDic["longitude"])")
                    }
                    
                }
            }
            
            do {
                try coreDataStack?.backgroundContext.save()
                completion(true)
            } catch let error {
                completion(false)
                fatalError("Saving background error \(error)")
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
            for aStyle in styleArrayOfDict {
                print("astyle \(aStyle)")
                let localId = aStyle["id"]?.stringValue
                let localName = aStyle["name"]
                Style(id: localId!, name: localName! as! String, context: (coreDataStack?.persistingContext)!)
            }
            
            // Save beer styles to disk
            do {
                try coreDataStack?.persistingContext.save()
            } catch {
                fatalError("Error saving styles")
            }
            break
            
        case .Breweries:
            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data")
                return
            }
            print("numberofpages:\(response["numberOfPages"]) results:\(response["totalResults"])")
            print("We are creating \(breweryArray.count) breweries")
            for breweryDict in breweryArray {
                // All conditions that prevent us from going to the brewery
                guard let locationInfo = breweryDict["locations"] as? NSArray?,
                    let locDic : [String:AnyObject] = locationInfo?[0] as! [String : AnyObject]?,
                    let openToPublic = locDic["openToPublic"],
                    openToPublic as! String == "Y",
                    locDic["latitude"]?.description != "",
                    locDic["longitude"]?.description != "",
                    locDic["longitude"] != nil,
                    locDic["latitude"] != nil
                    else { continue }
                //guard openToPublic as! String == "Y" else {return}
                // Extract location information
                //let locDic = locationInfo[0] as! [String : AnyObject]
                // Create the brewery object
                let thisBrewery : Brewery = Brewery(inName: breweryDict["name"] as! String,
                                                    latitude: locDic["latitude"]?.description,
                                                    longitude: locDic["longitude"]?.description,
                                                    url: locDic["website"] as! String?,
                                                    open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                                    id: locDic["id"]?.description,
                                                    context: (coreDataStack?.backgroundContext)!)
                print("creatd brewery object \(thisBrewery.objectID)")
                // Capture and download images for later use
                guard let imagesDict : [String:AnyObject] = breweryDict["images"] as? [String:AnyObject],
                    let imageURL : String = imagesDict["medium"] as! String?
                    else { continue }
                // Capture images asynchronously
                let queue = DispatchQueue(label: "Images")
                queue.async(qos: .utility) {
                    print("Getting images in background")
                    self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!,
                                                           forBrewery: thisBrewery,
                                                           updateManagedObjectID: thisBrewery.objectID)
                }
                
            }// for breweryDict in breweryArray {
            // Save all the Breweries in background context to disk
            do {
                try coreDataStack?.backgroundContext.save()
                print("save breweries to disk")
                completion(true)
            } catch let error {
                completion(false)
                fatalError("Saving background error \(error)")
            }
            break
            
            
        case .Brewery:
            guard let brewery = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data")
                return
            }
            let breweryDict = brewery[0]
            guard let locationInfo = breweryDict["locations"] as? NSArray else {
                // Can't build a brewery location if no location exists
                break
            }
            // Brewery stub to populate
            var thisBrewery : Brewery!
            
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
                                      context: (coreDataStack?.backgroundContext)!)
                // Capture and download images for later use
                if let imagesDict : [String:AnyObject] = breweryDict["images"] as? [String:AnyObject],
                    let imageURL : String = imagesDict["medium"] as! String? {
                    let queue = DispatchQueue(label: "Images")
                    queue.async(qos: .utility) {
                        print("Getting brewery images in background")
                        self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!, forBrewery: thisBrewery, updateManagedObjectID: thisBrewery.objectID)
                        
                    }
                }
            }
            // Save the Brewery in background context
            do {
                try coreDataStack?.backgroundContext.save()
            } catch let error {
                fatalError("Saving background error \(error)")
            }
            break
            
            
        case .BeersByABreweryID:
            // The Keys in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            // Extracting beer data array of dictionaries
            print("Capturing Beers By Brewery")
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data")
                completion(false)
                return
            }
            
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
                let thisBeer = Beer(id: id!, name: name ?? "", beerDescription: description ?? "", availability: available ?? "", context: (coreDataStack?.backgroundContext!)!)
                
                thisBeer.brewer = getBreweryByID(id: querySpecificID!, context: (coreDataStack?.backgroundContext)!)
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
            //}
            
            do {
                try coreDataStack?.backgroundContext.save()
                completion(true)
            } catch let error {
                completion(false)
                fatalError("Saving background error \(error)")
            }
            
            break
            
            
            //        default:
            //            break
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
    
    
    func isElementInDatabase(type: String,
                             id: String,
                             context: NSManagedObjectContext ) -> Bool {
        // Check to make sure we are not already in the database
        let request : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: type)
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
                self.coreDataStack!.backgroundContext.performAndWait(){
                    let beerForUpdate = self.coreDataStack!.backgroundContext.object(with: updateManagedObjectID) as! Beer
                    let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                    beerForUpdate.image = outputData
                    do {
                        try self.coreDataStack!.backgroundContext.save()
                        print("Imaged saved")
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
                self.coreDataStack!.backgroundContext.performAndWait(){
                    let breweryForUpdate = self.coreDataStack!.backgroundContext.object(with: updateManagedObjectID) as! Brewery
                    let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                    breweryForUpdate.image = outputData
                    do {
                        try self.coreDataStack!.backgroundContext.save()
                        print("Attention Brewery Imaged saved")
                    }
                    catch {
                        return
                    }
                }
            }
        }
        task.resume()
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
        case .Beers:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Beers
            break
        case .Styles:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Styles
            break
        case .Brewery:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Brewery
            break
        case .Breweries:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Breweries
            break
        case .BeersByABreweryID:
            // GET: /brewery/:breweryId/beers
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Brewery + "/" +
                querySpecificID! + "/" + Constants.BreweryDB.Methods.Beers
        default:
            break
        }
        
        // Add the API Key - QueryItem
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        let queryItem : URLQueryItem = NSURLQueryItem(name: Constants.BreweryParameterKeys.Key, value: Constants.BreweryParameterValues.APIKey) as URLQueryItem
        components.queryItems?.append(queryItem)
        
        // Build the other parameters
        for (key, value) in parameters {
            print(key,value)
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem as URLQueryItem)
        }
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
