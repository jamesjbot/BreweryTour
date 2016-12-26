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
    
    internal enum APIQueryOutputTypes {
        case BeersByName
        case BeersByStyleID
        case Styles
        case Breweries
        case BeersByBreweryID
    }
    
    
    // MARK: Variables
    private let coreDataStack = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack
    private let container = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext
    // TODO Remove debugging variable
    public var rejectedBreweries : Int = 0
    
    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> BreweryDBClient {
        struct Singleton {
            static var sharedInstance = BreweryDBClient()
        }
        return Singleton.sharedInstance
    }
    
    
    // MARK: Functions
    
    // Creates beer objects in the mainContext.
    private func createBeerObject(beer : [String:AnyObject],
                                  brewery: Brewery? = nil,
                                  brewerID: String? = nil,
                                  completion: @escaping (_ out : Beer) -> ()) {

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

        func setBeerPropertiesAndSave(brewery: Brewery,
                                      id: String, name: String,
                                      description: String,
                                      beerabv: String, beeribu: String,
                                      available: String) {
            var thisBeer : Beer!
            container?.performBackgroundTask(){
                (context) -> Void in
                context.perform {
                    thisBeer = Beer(id: id, name: name,
                                    beerDescription: description,
                                    availability: available,
                                    context: context)
                    thisBeer.brewer = context.object(with: (brewery.objectID)) as? Brewery
                    print("Flow 4\(beer["name"])")
                    thisBeer.breweryID = thisBeer.brewer?.id
                    thisBeer.isOrganic = beer["isOrganic"] as? String == "Y" ? true : false
                    if beer["styleId"] != nil {
                        thisBeer.styleID = (beer["styleId"] as! NSNumber).description
                    }
                    thisBeer.abv = beerabv
                    thisBeer.ibu = beeribu
                    print("\nBrewerydb \(#line) next line will non block for beer save backgroundcontext")
                    context.mergePolicy = NSMergePolicy.overwrite
                    do {
                        try context.save()
                        completion(thisBeer)
                        saveBeerImageIfPossible(beerDict: beer, beer: thisBeer)
                    } catch let error {
                        fatalError("Failed to save beer because of error:\n\(error)\n")
                    }
                    print("BreweryDb \(#line) Exiting Asynchronous block for:\(name)\n")
                    print("BreweryDb \(#line) Returning the beer we created.")
                }
            }
        }

        // Transform data into strings
        print("BreweryDB \(#line) Working to create Beer object in backgroundcontext)")
        let id: String = beer["id"] as! String
        print("BreweryDB \(#line) beername: \(beer["name"])")
        let name: String = beer["name"] as? String ?? ""
        let description: String = beer["description"] as? String ?? "No Information Provided"
        let beerabv: String = beer["abv"] as? String ?? "N/A"
        let beeribu: String = beer["ibu"] as? String ?? "N/A"
        let available = beer["available"]?["description"] as? String ?? "No Information Provided"
        if brewery == nil {
            self.getBreweryByID(id: brewerID!, context: self.readOnlyContext!){
                (brewer) -> Void in
                setBeerPropertiesAndSave(brewery: brewer!,
                                         id: id,
                                         name: name,
                                         description: description,
                                         beerabv: beerabv,
                                         beeribu: beeribu,
                                         available: available)
            }
        } else {
            setBeerPropertiesAndSave(brewery: brewery!,
                                     id: id,
                                     name: name,
                                     description: description,
                                     beerabv: beerabv,
                                     beeribu: beeribu,
                                     available: available)
        }
    }
    
    
    // The breweries are created sent back but they are not showing up in the table.
    // This will save background, main and persistent context
    private func createBreweryObject(breweryDict: [String:AnyObject],
                                     locationDict locDict:[String:AnyObject],
                                     completion: @escaping (_ out : Brewery) -> () ) {
        func saveBreweryImagesIfPossible(input: AnyObject?, inputBrewery : Brewery?) {
            if let imagesDict : [String:AnyObject] = input as? [String:AnyObject],
                let imageURL : String = imagesDict["icon"] as! String?,
                let targetBrewery = inputBrewery {
                print("BreweryDB \(#line) Prior to getting Brewery image")
                print("BreweryDB \(#line) Getting Brewery image in background")
                self.downloadImageToCoreDataForBrewery(aturl: NSURL(string: imageURL)!, forBrewery: targetBrewery, updateManagedObjectID: targetBrewery.objectID)
            }
        }
        var brewer : Brewery!
        print("\nBreweryDb \(#line) Brewery non Blocking for create brewery in backgroundContext\n\(breweryDict["name"])")
        // Why did I make this perform instead of performandWait
        // Changed back to performAndWait because map was boing populated with nothing
        // because this function returned before creating breweries
        // I may have used perform because it stalls the UI but this is in background context why would it stall the ui.
        /*
         I use perform because i get deadlocked with performandwait,
         The solution is to use perform and allow MapViewController to dynamically watch for changes to the beers..
         I use performAndWait because completion get called before breweries are created.
         */
        container?.performBackgroundTask() {
            (context) -> Void in
            context.perform {
            brewer = Brewery(inName: breweryDict["name"] as! String,
                             latitude: locDict["latitude"]?.description,
                             longitude: locDict["longitude"]?.description,
                             url: locDict["website"] as! String?,
                             open: (locDict["openToPublic"] as! String == "Y") ? true : false,
                             id: locDict["id"]?.description,
                             context: context)
                do {
                    try context.save()
                    print("BreweryDB \(#line) Exiting Brewery non blocking creationandsave\n\(breweryDict["name"])")
                    completion(brewer)
                    saveBreweryImagesIfPossible(input: breweryDict["images"], inputBrewery: brewer)
                } catch let error {
                    fatalError(error.localizedDescription)
                }
            }
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
        let theOutputType = APIQueryOutputTypes.Breweries
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
                
                print("BreweryDB \(#line)Total pages \(numberOfPages)")
                
                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                print("BreweryDB \(#line)Total pages \(numberOfPages)")
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
                                print("BreweryDB \(#line)page# \(i)")
                                print("BreweryDB \(#line)Prior to saving \(self.readOnlyContext?.updatedObjects.count)")
                                print("BreweryDB \(#line)Prior to saving hasChanges: \(self.readOnlyContext?.hasChanges)")
                                print("BreweryDB \(#line)Prior to saving \(self.readOnlyContext?.insertedObjects.count)")
                                print("BreweryDB \(#line)After saving \(self.readOnlyContext?.insertedObjects.count)")
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
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
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
            print("BreweryDB \(#line) We have this many results for that query \(numberOfResults)")
            
            print("BreweryDB \(#line) Total pages \(numberOfPages)")
            
            // Asynchronous page processing
            let queue : DispatchQueue = DispatchQueue.global()
            let group : DispatchGroup = DispatchGroup()
            
            for p in 1...numberOfPages {
                methodParameters[Constants.BreweryParameterKeys.Page] = p as AnyObject
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
                                       group: group)
                            print("BreweryDB \(#line) launched parsing on page# \(p)")
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
        print("BreweryDB \(#line) downloadBeersByBrewery completing with All Pages processed")
        completionHandler(true, "All Pages Processed downloadBeersByBrewery")
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
                    print("BreweryDb \(#line) downloadBeerByName returning completion Allpagesprocessed ")
                    completion(true, "All Pages Processed downloadBeersByName")
                    return
                }
                
                // Processing Pages
                let queue : DispatchQueue = DispatchQueue.global()
                let group = DispatchGroup()
                
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
                                           group: group)
                                print("BreweryDB \(#line) downloadBeersByName Firing group leave ")
                                group.leave()
                        }
                    }
                }
                group.notify(queue: queue){
                    print("BreweryDB \(#line) downloadBeersByName Completing with All Pages Processed")
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
                //print("\nBrewerydb \(#line) Preceding to Blocking for beerImage update in \(thisContext)")
                self.container?.performBackgroundTask({
                    (context) in
                    context.mergePolicy = NSMergePolicy.overwrite
                    context.perform(){
                        print("Brewerydb \(#line) Blocking on beerimage update ")
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
                        //                        print("BreweryDB \(#line) Beer Imaged saved in \(thisContext) for beer \(forBeer.beerName)")
                        //                    }
                        //                    catch {
                        //                        return
                        //                    }
                        print("BreweryDb \(#line) Completed blocking on beer image update\n")
                    }
                })
            }
        }
        task.resume()
    }
    
    
    
    // Downloads Beer Styles
    internal func downloadBeerStyles(completionHandler: @escaping (_ success: Bool,_ msg: String?) -> Void ) {
        let methodParameter : [String:AnyObject] = [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryOutputTypes.Styles,
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
                       outputType: APIQueryOutputTypes.Styles,
                       completion: completionHandler)
            return
        }
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
                
                //                guard let numberOfResults = responseJSON["totalResults"] as! Int? else {
                //                    completion(false, "No results")
                //                    return
                //                }
                //
                //                print("BreweryDB \(#line)We have this many results for that query \(numberOfResults)")
                
                // Process subsequent records
                self.parse(response: responseJSON as NSDictionary,
                           querySpecificID:  nil,
                           outputType: theOutputType,
                           completion: completion)
                // The following block of code downloads all subsequesnt pages
                guard numberOfPages > 1 else {
                    completion(true, "All Pages Processed downloadBreweryByName")
                    return
                }
                
                print("BreweryDB \(#line)Total pages \(numberOfPages)")
                
                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                print("BreweryDB \(#line)Total pages \(numberOfPages)")
                
                // TODO Why does downloading BreweryByNames use BreweryByStyleID
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
                                           group: group)
                                print("BreweryDB \(#line)page# \(i)")
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
        print("BreweryDB \(#line) Async DownloadBreweryImage in backgroundContext \(forBrewery.name)")
        
        let session = URLSession.shared
        let task = session.dataTask(with: aturl as URL){
            (data, response, error) -> Void in
            print("BreweryDB \(#line) Returned from Async DownloadBreweryImage ")
            if error == nil {
                if data == nil {
                    return
                }
                // Upgraded code change to thisContext, and remove the perfromandwait?
                print("\nBreweryDB \(#line) preceeding to block brewery image update in backgroundcontext")
                self.container?.performBackgroundTask({
                    (context) in
                    context.mergePolicy = NSMergePolicy.overwrite
                    context.perform() {
                        print("BreweryDB \(#line) blocking on brewery image update ")
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
                        //                        print("BreweryDB \(#line) Attention Brewery Imaged saved in \(thisContext.name) for brewery \(forBrewery.name)")
                        //                    }
                        //                    catch let error {
                        //                        fatalError("Error \(error)")
                        //                    }
                        print("BreweryDB \(#line) Complete blocking on brewery image update\n ")
                    }
                })
            }
        }
        task.resume()
    }
    
    
    // Debugging function to list the number of results for a style.
    internal func downloadStylesCount(styleID : String,
                                      completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        let methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject,
            Constants.BreweryParameterKeys.Page : "1" as AnyObject
        ]
        let outputURL : NSURL =
            createURLFromParameters(queryType: APIQueryOutputTypes.BeersByStyleID,
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
            print("BreweryDB \(#line) We have this many results for that query \(numberOfResults)")
            
            print("BreweryDB \(#line) Total pages \(numberOfPages)")
            completion(true, "\(numberOfResults)")
        }
    }
    
    // TODO make this return by completion handler
    private func getBeerByID(id: String, context: NSManagedObjectContext) -> Beer? {
        //print("BreweryDB \(#line)Attempting to get beer \(id)")
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
            return nil
        }
        return nil
    }
    

    private func getBreweryByID(id : String,
                                context : NSManagedObjectContext,
                                completion: @escaping (Brewery?) -> Void ) {
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [id])
        context.perform {
            do {
                if let brewery : [Brewery] = try context.fetch(request){
                    //This type is in the database
                    guard brewery.count > 0 else {
                        completion(nil)
                        return
                    }
                    completion(brewery.first)
                    return
                }
            } catch {
            }
            completion(nil)
            return
        }
    }
    
    
    // Parse results into objects
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       outputType: APIQueryOutputTypes,
                       completion: (( (_ success :  Bool, _ msg: String?) -> Void )?),
                       group: DispatchGroup? = nil){
        
        // Process every query type accordingly
        switch outputType {
            
        // Beers query
        case APIQueryOutputTypes.BeersByStyleID:
            // No beer data was returned which can happen
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "Failed Request \(#line) \(#function)")
                return
            }
            print("BreweryDB \(#line) Beerloop starts after ")
            createBeerLoop: for beer in beerArray {
                print("Brewerydb \(#line) In beer loop ")
                // Check to see if this beer is in the database already, and skip if so
                guard getBeerByID(id: beer["id"] as! String, context: readOnlyContext!) == nil else {
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
                    // We can't visit a brewery if it's not open to the public
                    // or we don't have coordinates
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
                    var dbBrewery : Brewery!
                    getBreweryByID(id: locDic["id"] as! String, context: readOnlyContext!){
                        (Brewery) -> Void in
                        dbBrewery = Brewery
                        if dbBrewery == nil { // Create a brewery object when none.
                            self.createBreweryObject(breweryDict: breweryDict!, locationDict: locDic) {
                                (Brewery) -> Void in
                                dbBrewery = Brewery
                                guard dbBrewery != nil else {
                                    completion!(false, "Error saving data")
                                    return
                                }
                                self.createBeerObject(beer: beer, brewery: dbBrewery) {
                                    (Beer) -> Void in
                                }
                            }
                        } else { // Brewery already in Coredata
                            print("BreweryDB \(#line) Brewery already  in Coredata: \(dbBrewery.name)")
                            self.createBeerObject(beer: beer, brewery: dbBrewery, completion: {
                                (beer)-> Void in })
                        }
                    }
                }
            } // end of beer loop
            // This page of results has processed signal GCD that it's complete.
            group?.leave()
            break
            
        case .Styles:
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
            // TODO experiment moving this block of code up one bracket
            // and end with a return, this will save all the styles after we are done.
            // This line of code will run immediately because the above is a perform
            // Save beer styles in main and persistent.
//            do {
//                print("BreweryDB \(#line) Styles download now saving in MainContext ")
//                // TODO Reinstate this change
//                //try coreDataStack?.mainContext.save()
//                try coreDataStack?.saveMainContext()
//                completion!(true, "Success saving all new styles.")
//                return
//            } catch {
//                completion!(false, "Failed saving new styles")
//                return
//            }
            return
            break
            
            
        case .Breweries:
            print("BreweryDB \(#line) Parse type .Breweries ")
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
                        rejectedBreweries += 1
                        continue
                }
                
                guard let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                    let openToPublic = locDic["openToPublic"],
                    openToPublic as! String == "Y",
                    locDic["longitude"] != nil,
                    locDic["latitude"] != nil
                    else {
                        rejectedBreweries += 1
                        continue breweryLoop
                }
                
                // Don't repeat breweries in the database
                getBreweryByID(id: locDic["id"] as! String, context: readOnlyContext!) {
                    (Brewery) -> Void in
                    if Brewery == nil {
                        self.createBreweryObject(breweryDict: breweryDict,                                                   locationDict: locDic){
                            (thisbrewery) -> Void in
                        }
                    } else { // Consider removing this else clause.
                        self.rejectedBreweries += 1
                    }
                }
//                guard thisbrewery == nil else {
//                    rejectedBreweries += 1
//                    continue
//                }
            }
            // TODO Contemplate deleting this block of code.
            //Go back to the breweryArray and save another brewery
            //Save all the Breweries in background context to disk
//            do {
//                print("BreweryDB \(#line) Saving from .Breweries switch case of parse function ")
//                try coreDataStack?.persistingContext.save()
//                print("BreweryDB \(#line) Brewery Saved to Persisting context")
//                completion!(true, "Success")
//                return
//            } catch {
//                completion!(false, "Failed Request \(#line) \(#function)")
//                return
//            }
            // Completed processing this page of breweries
            completion!(true, "Success")
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
                print("BreweryDB \(#line)---------------------NextBeer---------------------")
                // Creating beer
                // Check to see if this beer is in the database already
                var thisBeer = getBeerByID(id: beer["id"] as! String, context: readOnlyContext!)
                // If the beer is in the coredata skip adding it
                guard thisBeer == nil else {
                    continue beerLoop
                }
                // This beer has no brewery information, continue with the next beer
                guard beer["name"] != nil && beer["name"] as! String != "" else {
                    continue beerLoop
                }
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
                    
                    guard breweryDict["name"] != nil else {
                        continue breweryLoop
                    }
                    
                    // Check to make sure the brewery is not already in the database
                    var newBrewery : Brewery!
                    getBreweryByID(id: locDic["id"] as! String, context: readOnlyContext!){
                        (brewery) -> Void in
                        if newBrewery == nil { // Create a brewery object
                            self.createBreweryObject(breweryDict: breweryDict,
                                                     locationDict: locDic,
                                                     completion: { (newBrewery) -> Void in
                                self.createBeerObject(beer: beer,
                                                      brewery: newBrewery,
                                                      completion: { (beer) -> Void in })
                                                        })
                        } else { // Just create beer
                            self.createBeerObject(beer: beer,
                                                  brewery: newBrewery,
                                                  completion: { (beer) -> Void in })
                        }
                    }
                    // Future Improvement.
                    // Currently datamodel cannot accomodate multple brewery locations for a beer
                    break
                } // End of For Brewery
                // This will save every beer
                
            } // end of beer loop
            break
            
        case .BeersByBreweryID:
            // Since were ware querying by brewery ID we can be guaranteed that the brewery exists.
            print("BreweryDB \(#line) Capturing Beers By BreweryID")
            print("BreweryDB \(#line) Response: \(response) ")
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                // Failed to extract data
                completion!(false, "There are no beers listed for this brewer.")
                return
            }
            
            print("BreweryDB \(#line) why is this called twice. This many beers at this brewery: \(beerArray.count)")
            
            for beer in beerArray {
                print("BreweryDB \(#line)---------------------NextBeer---------------------")
                // Create the coredata object for each beer
                // Test to see if beer is already in context
                let id : String? = beer["id"] as? String
                let dbBeer = getBeerByID(id: id!, context: readOnlyContext!)
                guard dbBeer == nil else {
                    print("BreweryDB \(#line)Encountered a beer of this type already skipping creation")
                    continue
                }
                // Get the brewery based on objectID
                getBreweryByID(id: querySpecificID!, context: readOnlyContext!) {
                    (dbBrewery) -> Void in
                    self.createBeerObject(beer: beer,
                                     brewery: dbBrewery,
                                     completion: { (beer) -> Void in})
                }
            }
            break
        }
    }
    
// TODO did I remove all of these.
//    private func saveBackground() {
//        coreDataStack?.backgroundContext.performAndWait {
//            do {
//                try self.coreDataStack?.backgroundContext.save()
//            } catch let error {
//                fatalError("error:\n\(error)")
//            }
//        }
//        
//    }
    
    
    
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
    
    

    
//    private func saveMain() {
//        print("BreweryDB \(#line) Saving MainContext called ")
//        coreDataStack?.mainContext.performAndWait {
//            do {
//                try self.coreDataStack?.saveMainContext()
//                //try self.coreDataStack?.savePersistingContext()
//                //try coreDataStack?.mainContext.save()
//                print("BreweryDB \(#line) All beers before this have been saved")
//                //print("BreweryDB \(#line) MainContext objects should be in Persistent Context now <------------------------")
//                //try coreDataStack?.persistingContext.save()
//                //true
//            } catch let error {
//                print("BreweryDB \(#line) We died on the coredataSave <----- ")
//                print("The error is \n\(error)")
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


