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
    
    var d_timestopass: Int = 0
    
    // MARK: Enumerations
    
    internal enum APIQueryResponseProcessingTypes {
        case BeersFollowedByBreweries
        // Called from the category style view controller
        case Styles
        // Initial called when the app starts up
        case Breweries
        // Calle when you search for a brewery on the category view controller
        case BeersByBreweryID
        // Called when you select a brewery on the category view controller.
    }
    
    fileprivate let breweryAndBeerCreator = BreweryAndBeerCreationQueue()

    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    private let container = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext
    private let backContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.newBackgroundContext()

    // MARK: Variables

    private var breweryDictionary = [String:Brewery]()

    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> BreweryDBClient {
        struct Singleton {
            static var sharedInstance = BreweryDBClient()
        }
        return Singleton.sharedInstance
    }
    
    
    // MARK: Functions

    func saveBeerImageIfPossible(beerDict: [String:AnyObject] , beer: Beer) {
        if let images : [String:AnyObject] = beerDict["labels"] as? [String:AnyObject],
            let medium = images["medium"] as! String?  {
            beer.imageUrl = medium
            //let queue = DispatchQueue(label: "Images")
            print("BreweryDB \(#line) Prior to getting Beer image")
            print("BreweryDB \(#line) In queue Async Getting Beer image in background")
            self.downloadBeerImageToCoreData(aturl: NSURL(string: beer.imageUrl!)!, forBeer: beer, updateManagedObjectID: beer.objectID)
        }
    }
    //                        saveBeerImageIfPossible(beerDict: beer, beer: thisBeer)


    // Creates beer objects in the mainContext.
    private func createBeerObject(beer : [String:AnyObject],
                                  brewery: Brewery? = nil,
                                  brewerID: String,
                                  completion: @escaping (_ out : Beer) -> ()) {

        let beer = BeerData(inputAvailability: beer["available"]?["description"] as? String ?? "No Information Provided",
                            inDescription: beer["description"] as? String ?? "No Information Provided",
                            inName: beer["name"] as? String ?? "",
                            inBrewerId: brewerID,
                            inId: beer["id"] as! String,
                            inImageURL: beer["labels"]?["medium"] as? String ?? "",
                            inIsOrganic: beer["isOrganic"] as? String == "Y" ? true : false,
                            inStyle: (beer["styleId"] as! NSNumber).description,
                            inAbv: beer["abv"] as? String ?? "N/A",
                            inIbu: beer["ibu"] as? String ?? "N/A")

        breweryAndBeerCreator.queueBeer(beer)
    }

    
    // The breweries are created sent back but they are not showing up in the table.
    // This will save background, main and persistent context
    private func createBreweryObject(breweryDict: [String:AnyObject],
                                     locationDict locDict:[String:AnyObject],
                                     completion: @escaping (_ out : Brewery) -> () ) {
        let breweryData = BreweryData(
            inName: breweryDict["name"] as! String,
            inLatitude: (locDict["latitude"]?.description)!,
            inLongitude: (locDict["longitude"]?.description)!,
            inUrl: (locDict["website"] as! String? ?? ""),
            open: (locDict["openToPublic"] as! String == "Y") ? true : false,
            inId: (locDict["id"]?.description)!,
            context: (coreDataStack?.breweryCreationContext)!)

        breweryAndBeerCreator.queueBrewery(breweryData)
    }


    func saveBreweryImagesIfPossible(input: AnyObject?, inputBrewery : Brewery?) {
        if let imagesDict : [String:AnyObject] = input as? [String:AnyObject],
            let imageURL : String = imagesDict["icon"] as! String?,
            let targetBrewery = inputBrewery {
            //print("BreweryDB \(#line) Prior to getting Brewery image")
            //print("BreweryDB \(#line) Getting Brewery image in background")
            self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!, forBrewery: targetBrewery, updateManagedObjectID: targetBrewery.objectID)
        }
    }
    //saveBreweryImagesIfPossible(input: breweryDict["images"], inputBrewery: brewer)


        
    
    private func createURLFromParameters(queryType: APIQueryResponseProcessingTypes,
                                         querySpecificID: String?,
                                         parameters: [String:AnyObject]) -> NSURL {
        // The url currently takes the form of
        // "http://api.brewerydb.com/v2/beers?key=\(Constants.BreweryParameterValues.APIKey)&format=json&isOrganic=Y&styleId=1&withBreweries=Y")
        
        let components = NSURLComponents()
        components.scheme = Constants.BreweryDB.APIScheme
        components.host = Constants.BreweryDB.APIHost
        
        switch queryType {
        case .BeersFollowedByBreweries:
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
            //print("BreweryDB \(#line)key,value")
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem as URLQueryItem)
        }
        
        // Finally Add the API Key - QueryItem
        let queryItem : URLQueryItem = NSURLQueryItem(name: Constants.BreweryParameterKeys.Key, value: Constants.BreweryParameterValues.APIKey) as URLQueryItem
        components.queryItems?.append(queryItem)
        
        print("BreweryDB \(#line) \(components.url!)")
        return components.url! as NSURL
    }
    
    
    // Query for all breweries
    // TODO not completing
    internal func downloadAllBreweries(completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        let theOutputType = APIQueryResponseProcessingTypes.Breweries
        var methodParameters  = [
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
                    completion(true, "All Pages Processed downloadAllBreweries")
                    return
                }
                
                //print("BreweryDB \(#line)Total pages \(numberOfPages)")
                
                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                //print("BreweryDB \(#line)Total pages \(numberOfPages)")
                for i in 2...numberOfPages {
                    //TODO for i in 2...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: theOutputType,
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
                                           outputType: theOutputType,
                                           completion: completion,
                                           group: group)
                                //print("BreweryDB \(#line)page# \(i)")
                                //print("BreweryDB \(#line)Prior to saving \(self.readOnlyContext?.updatedObjects.count)")
                                //print("BreweryDB \(#line)Prior to saving hasChanges: \(self.readOnlyContext?.hasChanges)")
                                //print("BreweryDB \(#line)Prior to saving \(self.readOnlyContext?.insertedObjects.count)")
                                //print("BreweryDB \(#line)After saving \(self.readOnlyContext?.insertedObjects.count)")
                                group.leave()
                        }
                    }
                }
                group.notify(queue: queue) {
                    completion(true, "All Pages Processed downloadAllBreweries")
                }
        }
        return
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
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)
        
        // Initial Alamofire Request to determine Results and Pages of Results we have to process
        var numberOfPages: Int!
        
        Alamofire.request(outputURL.absoluteString!).responseJSON {
            response in
            guard response.result.isSuccess else {
                completion(false, "Failed Request \(#line) \(#function)")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completion(false, "Failed Request \(#line) \(#function)")
                return
            }
            guard let numberOfPagesInt = responseJSON["numberOfPages"] as! Int? else {
                completion(false, "No results")
                return
            }
            guard let numberOfResults = responseJSON["totalResults"] as! Int? else {
                completion(false, "No results")
                return
            }
            numberOfPages = numberOfPagesInt
            //print("BreweryDB \(#line) We have this many results for that query \(numberOfResults)")
            
            //print("BreweryDB \(#line) Total pages \(numberOfPages)")
            
            // Asynchronous page processing
            let queue : DispatchQueue = DispatchQueue.global(qos: .utility)
            let group : DispatchGroup = DispatchGroup()
            for p in 1...numberOfPages {
                methodParameters[Constants.BreweryParameterKeys.Page] = p as AnyObject
                let outputURL : NSURL = self.createURLFromParameters(queryType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                                                     querySpecificID: nil,
                                                                     parameters: methodParameters)
                group.enter()
                queue.async(group: group) {
                //queue.sync() {
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
                                       outputType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                       completion: completion,
                                       group: group)
                    } //Outside alamo but inside async
                } //Outside queue.async
            }  // Outside for loop
            
            group.notify(queue: queue) {
                completion(true, "All Pages Processed DownloadBeerAndBreweriesByStyleID")
            }
        }
        return
    }
    
    
    // Download all beers from a Brewery
    // GET: /brewery/:breweryId/beers
    internal func downloadBeersBy(brewery: Brewery,
                                  completionHandler: @escaping ( _ success: Bool, _ msg: String? ) -> Void ) {
        let consistentOutput = APIQueryResponseProcessingTypes.BeersByBreweryID
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
            // Note: This request does not return "totalResults", so we don't check for it
            // query is brewery/breweryID/beers
            // Returned data is of format
            // "message":"READ ONLY MODE: Request Successful"
            // "data":[...]
            // "status":"success"
            
            self.parse(response: responseJSON as NSDictionary,
                       querySpecificID : brewery.id,
                       outputType: consistentOutput,
                       completion: completionHandler)
        }
        //print("BreweryDB \(#line) downloadBeersByBrewery completing with All Pages processed")
        completionHandler(true, "All Pages Processed downloadBeersByBrewery")
        return
    }
    
    
    // Query for beers with a specific name
    internal func downloadBeersBy(name: String,
                                  completion: @escaping (_ success : Bool , _ msg : String? ) -> Void ) {
        let theOutputType = APIQueryResponseProcessingTypes.BeersFollowedByBreweries
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
                    print("BreweryDb \(#line) downloadBeerByName returning completion Allpagesprocessed ")
                    completion(true, "All Pages Processed downloadBeersByName")
                    return
                }
                
                // Processing Pages
                let queue : DispatchQueue = DispatchQueue.global()
                let group = DispatchGroup()
                
                for i in 2...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
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
                                           outputType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                           completion: completion,
                                           group: group)
                                print("BreweryDB \(#line) downloadBeersByName Firing group leave ")
                                group.leave()
                        }
                    }
                }
                group.notify(queue: queue){
                    //print("BreweryDB \(#line) downloadBeersByName Completing with All Pages Processed")
                    completion(true, "All Pages Processed downloadBeersByName")
                }
        }
    }

    
    // Download images in the background then update Coredata when complete
    // Beer images are currently being grabbed and saved in the main context
    // This help with updateing selected beers screen I guess.
    internal func downloadBeerImageToCoreData( aturl: NSURL,
                                               forBeer: Beer,
                                               updateManagedObjectID: NSManagedObjectID) {
        // Begin Upgraded code
        // print("BreweryDB \(#line) Async DownloadBeerImage in backgroundContext\(forBeer.beerName)")
        // TODO Breaking BreweryList and MapView Style selection, MapView Brewery selection will be unharmed.
        // End Upgraded code
        print("BreweryDB \(#line) Async DownloadBeerImage in background context:\(forBeer.beerName!)")
        let session = URLSession.shared
        let task = session.dataTask(with: aturl as URL){
            (data, response, error) -> Void in
            //print("BreweryDB \(#line) Returned from Async DownloadBeerImage:\(forBeer.beerName!)")
            if error == nil {
                if data == nil {
                    return
                }
                // Upgraded code
                //let thisContext = self.coreDataStack?.backgroundContext
                ////print("\nBrewerydb \(#line) Preceding to Blocking for beerImage update in \(thisContext)")
                self.container?.performBackgroundTask({
                    (context) in
                    context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
                    context.perform(){
                        //print("Brewerydb \(#line) Blocking on beerimage update ")
                        //self.coreDataStack!.mainContext.performAndWait(){
                        // Upgraded code
                        let beerForUpdate = context.object(with: updateManagedObjectID) as! Beer
                        //let beerForUpdate = self.coreDataStack?.mainContext.object(with: updateManagedObjectID) as! Beer
                        let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                        beerForUpdate.image = outputData
                        do {
                            try context.save()
                        } catch let error {
                            fatalError("error:\n\(error)")
                        }
                        //                    do {
                        //                        // Upgraded code
                        //                        try thisContext?.save()
                        //                        //try self.coreDataStack?.mainContext.save()
                        //                        //print("BreweryDB \(#line) Beer Imaged saved in \(thisContext) for beer \(forBeer.beerName)")
                        //                    }
                        //                    catch {
                        //                        return
                        //                    }
                        //print("BreweryDb \(#line) Completed blocking on beer image update\n")
                    }
                })
            }
        }
        task.resume()
    }
    
    
    
    // Downloads Beer Styles
    internal func downloadBeerStyles(completionHandler: @escaping (_ success: Bool,_ msg: String?) -> Void ) {
        let methodParameter : [String:AnyObject] = [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryResponseProcessingTypes.Styles,
                                                        querySpecificID: nil,
                                                        parameters: methodParameter)
        Alamofire.request(outputURL.absoluteString!).responseJSON(){
            response in
            // Note: Styles Request does not return number of results.
            guard response.result.isSuccess else {
                completionHandler(false,"Failed Request \(#line) \(#function)")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completionHandler(false, "Failed Request \(#line) \(#function)")
                return
            }

            // All the beer styles currently fit on one page.
            self.parse(response: responseJSON as NSDictionary,
                       querySpecificID:  nil,
                       outputType: APIQueryResponseProcessingTypes.Styles,
                       completion: completionHandler)
            return
        }
    }
    
    
    // Query for breweries with a specific name
    internal func downloadBreweryBy(name: String, completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        //print("BreweryDb \(#line) DownloadbrewerybyName []() ")
        let theOutputType = APIQueryResponseProcessingTypes.Breweries
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
                guard let numberOfResults = responseJSON["totalResults"] as! Int? else {
                    completion(false, "No results")
                    return
                }

                //print("BreweryDB \(#line) We have this many results for that query \(numberOfResults)")

                // Process subsequent records
//                self.parse(response: responseJSON as NSDictionary,
//                           querySpecificID:  nil,
//                           outputType: theOutputType,
//                           completion: completion)
                // The following block of code downloads all subsequesnt pages
//                guard numberOfPages > 1 else {
//                    completion(true, "All Pages Processed downloadBreweryByName")
//                    return
//                }

                //print("BreweryDB \(#line)Total pages \(numberOfPages)")
                
                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                //print("BreweryDB \(#line)Total pages \(numberOfPages)")
                
                // TODO Why does downloading BreweryByNames use BreweryByStyleID
                for i in 1...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: theOutputType,
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
                                           outputType: theOutputType,
                                           completion: completion,
                                           group: group)
                                group.leave()
                        }
                    }
                }
                group.notify(queue: queue) {
                    completion(true, "All Pages Processed downloadBreweryByName")
                }
        }
        return
    }
    
    
    // Download images in the background for a brewery
    internal func downloadImageToCoreDataForBrewery( aturl: NSURL,
                                                     forBrewery: Brewery,
                                                     updateManagedObjectID: NSManagedObjectID) {
        // Upgraded code.
        //let thisContext : NSManagedObjectContext = (coreDataStack?.backgroundContext)!
        //print("BreweryDB \(#line) Async DownloadBreweryImage in backgroundContext \(forBrewery.name)")
        
        let session = URLSession.shared
        let task = session.dataTask(with: aturl as URL){
            (data, response, error) -> Void in
            //print("BreweryDB \(#line) Returned from Async DownloadBreweryImage ")
            if error == nil {
                if data == nil {
                    return
                }
                // Upgraded code change to thisContext, and remove the perfromandwait?
                //print("\nBreweryDB \(#line) preceeding to block brewery image update in backgroundcontext")
                self.container?.performBackgroundTask({
                    (context) in
                    context.mergePolicy = NSMergePolicy.overwrite
                    context.perform() {
                        //print("BreweryDB \(#line) blocking on brewery image update ")
                        let breweryForUpdate = context.object(with: updateManagedObjectID) as! Brewery
                        let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData
                        breweryForUpdate.image = outputData
                        // Upgraded code change this to thisContext.
                        do {
                            try context.save()
                        } catch let error {
                            fatalError("Error:\n\(error)")
                        }
                        //self.saveBackground()
                        //                    do {
                        //                        try thisContext.save()
                        //                        //print("BreweryDB \(#line) Attention Brewery Imaged saved in \(thisContext.name) for brewery \(forBrewery.name)")
                        //                    }
                        //                    catch let error {
                        //                        fatalError("Error \(error)")
                        //                    }
                        //print("BreweryDB \(#line) Complete blocking on brewery image update\n ")
                    }
                })
            }
        }
        task.resume()
    }
    
    
    // Debugging function to list the number of results for a style.
//    internal func downloadStylesCount(styleID : String,
//                                      completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
//        let methodParameters  = [
//            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
//            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
//            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject,
//            Constants.BreweryParameterKeys.Page : "1" as AnyObject
//        ]
//        let outputURL : NSURL =
//            createURLFromParameters(queryType: APIQueryResponseProcessingTypes.Styles,
//                                    querySpecificID: nil,
//                                    parameters: methodParameters)
//        
//        // Initial Alamofire Request to determine Results and Pages of Results we have to process
//        var numberOfPages: Int!
//        Alamofire.request(outputURL.absoluteString!).responseJSON {
//            response in
//            guard response.result.isSuccess else {
//                completion(false, "Failed Request \(#line) \(#function)")
//                return
//            }
//            guard let responseJSON = response.result.value as? [String:AnyObject] else {
//                completion(false, "Failed Request \(#line) \(#function)")
//                return
//            }
//            guard let numberOfPagesInt = responseJSON["numberOfPages"] as! Int? else {
//                completion(false, "No results")
//                return
//            }
//            guard let numberOfResults = responseJSON["totalResults"] as! Int? else {
//                completion(false, "No results")
//                return
//            }
//            numberOfPages = numberOfPagesInt
//            //print("BreweryDB \(#line) We have this many results for that query \(numberOfResults)")
//            
//            //print("BreweryDB \(#line) Total pages \(numberOfPages)")
//            completion(true, "\(numberOfResults)")
//        }
//    }
    
    // TODO make this return by completion handler
//    private func getBeerByID(id: String, context: NSManagedObjectContext) -> Beer? {
//        //print("BreweryDB \(#line)Attempting to get beer \(id)")
//        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
//        request.sortDescriptors = []
//        request.predicate = NSPredicate(format: "id = %@", argumentArray: [id])
//        do {
//            if let beer : [Beer] = try container?.newBackgroundContext()
//.fetch(request) {
//                //This type is in the database
//                guard beer.count > 0 else {
//                    return nil}
//                return beer[0]
//            }
//        } catch {
//            return nil
//        }
//        return nil
//    }


//    private func getBreweryByID(id : String,
//                                context : NSManagedObjectContext,
//                                completion: @escaping (Brewery?) -> Void ) {
//        completion(breweryDictionary[id])
//        return
//        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
//        request.sortDescriptors = []
//        request.predicate = NSPredicate(format: "id = %@", id)
//        context.performAndWait {
//            do {
//                // TODO there is a crash here, when I try to access a long running style 
//                // and then switch to the mapview.
//                var breweries : [Brewery] = try context.fetch(request)
//                if breweries != nil {
//                    //This type is in the database
//                    guard breweries.count > 0 else {
//                        completion(nil)
//                        return
//                    }
//                    completion(breweries.first)
//                    return
//                }
//            } catch let error {
//                fatalError(error as! String)
//            }
//            completion(nil)
//            return
//        }
//    }

    
    // Parse results into objects
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       outputType: APIQueryResponseProcessingTypes,
                       completion: (( (_ success :  Bool, _ msg: String?) -> Void )?),
                       group: DispatchGroup? = nil){
        
        // Process every query type accordingly
        switch outputType {
            
        // Beers query
        case APIQueryResponseProcessingTypes.BeersFollowedByBreweries:
            // No beer data was returned which can happen
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "Failed Request No data was returned")
                return
            }
            createBeerLoop: for beer in beerArray {
                /* Assume this beer is not in the database.
                 Send all beers to creation process unique constraints will
                 block duplicate entries
                */

                // This beer has no brewery information, continue with the next beer
                guard let breweriesArray = beer["breweries"]  else {
                    continue createBeerLoop
                }

                // This beer has no style id skip it
                guard beer["styleId"] != nil else {
                    continue createBeerLoop
                }

                breweryLoop: for brewery in (breweriesArray as! Array<AnyObject>) {
                    let breweryDict = brewery as? [String : AnyObject]
                    // There is no location info to display on the map.
                    guard let locationInfo = breweryDict?["locations"] as? NSArray else {
                        continue createBeerLoop
                    }
                    // We can't visit a brewery if it's not open to the public
                    // or we don't have coordinates
                    guard let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                        locDic["openToPublic"] as! String == "Y" &&
                            locDic["longitude"] != nil && locDic["latitude"] != nil else {
                                continue createBeerLoop
                    }
                    // Sometimes the breweries have no name, making it useless
                    guard breweryDict?["name"] != nil else {
                        continue breweryLoop
                    }

                    // Cant create this beer if we can't link it to a brewery
                    guard locDic["id"]?.description != nil else {
                        continue createBeerLoop
                    }

                    // Assume brewery not in database.
                    // Send all brweries to creation process
                    createBreweryObject(breweryDict: breweryDict!, locationDict: locDic) {
                        (Brewery) -> Void in
                    }
                    let brewersID = (locDic["id"]?.description)!
                    createBeerObject(beer: beer, brewerID: brewersID) {
                        (Beer) -> Void in
                    }
                    break breweryLoop
                } //  of brewery loop
            } // end of beer loop
            // This page of results has processed signal GCD that it's complete.
            // TODO crash occured on the group.leave.1
            //group?.leave()
            break

        case .Styles:
            print("BreweryDB \(#line) Parse type .Styles ")
            // Styles are saved on the persistingContext because they don't change often.
            // We must have data to process
            // Save the multiple styles from the server
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "No styles data" )
                return
            }
            // Check to see if the style is already in coredata then skip, else add
            let request = NSFetchRequest<Style>(entityName: "Style")
            request.sortDescriptors = []
            readOnlyContext?.perform {
                for aStyle in styleArrayOfDict {
                    let localId = aStyle["id"]?.stringValue
                    let localName = aStyle["name"]
                    do {
                        request.predicate = NSPredicate(format: "id = %@", localId!)
                        let results = try self.readOnlyContext?.fetch(request)
                        if (results?.count)! > 0 {
                            continue
                        }
                    } catch {
                        completion!(false, "Failed Reading Styles from database")
                        return
                    }
                    // When style not present adds new style into MainContext
                    self.container?.performBackgroundTask({
                        (context) in
                        Style(id: localId!, name: localName! as! String, context: context)
                        do {
                            try context.save()
                        } catch let error {
                            fatalError("Error saving style\n\(error)")
                        }
                    })
                }
            }
            return
            break
            
            
        case .Breweries:
            //print("BreweryDB \(#line) Parse type .Breweries ")
            guard let pagesOfResult = response["numberOfPages"] as? Int else {
                // The number of pages means we cant pull in any breweries
                completion!(false, "No results returned")
                return
            }

            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                //Unable to parse Brewery Failed to extract data, there was no data component
                completion!(false, "Network error please try again")
                return
            }

            // This for loop will asynchronousy launch brewery creation.
            breweryLoop: for breweryDict in breweryArray {
                // Can't build a brewery location if no location exist
                guard let locationInfo = breweryDict["locations"] as? NSArray
                    else {
                        //rejectedBreweries += 1
                        continue
                }

                guard let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                    let openToPublic = locDic["openToPublic"],
                    openToPublic as! String == "Y",
                    locDic["longitude"] != nil,
                    locDic["latitude"] != nil
                    else {
                        //rejectedBreweries += 1
                        continue breweryLoop
                }

                // Don't repeat breweries in the database
                createBreweryObject(breweryDict: breweryDict,
                                    locationDict: locDic){
                    (thisbrewery) -> Void in
                }
            }
            completion!(true, "Success")
            break
            
        case .BeersByBreweryID:
            // Since were are querying by brewery ID we can be guaranteed that 
            // the brewery exists and we can use the querySpecificID!.
            // No beer data was returned which can happen
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                // Failed to extract data
                completion!(false, "There are no beers listed for this brewer.")
                return
            }
            for beer in beerArray {
                createBeerObject(beer: beer, brewerID: querySpecificID!) {
                    (Beer) -> Void in
                }
            }
            break
        }
    }

//    private func saveMain() {
//        //print("BreweryDB \(#line) Saving MainContext called ")
//        coreDataStack?.mainContext.performAndWait {
//            do {
//                try self.coreDataStack?.saveMainContext()
//                //try self.coreDataStack?.savePersistingContext()
//                //try coreDataStack?.mainContext.save()
//                //print("BreweryDB \(#line) All beers before this have been saved")
//                ////print("BreweryDB \(#line) MainContext objects should be in Persistent Context now <------------------------")
//                //try coreDataStack?.persistingContext.save()
//                //true
//            } catch let error {
//                //print("BreweryDB \(#line) We died on the coredataSave <----- ")
//                //print("The error is \n\(error)")
//                fatalError()
//            }
//        }
//    }

//    private func savePersitent() -> Bool {
//        do {
//            try coreDataStack?.persistingContext.save()
//            return true
//        } catch let error {
//            return false
//        }
//    }
    

}


