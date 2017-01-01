//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This is the api driver, that makes all the requests to the breweryDB
 This will download and parse all the data for the system.
 

 Internals
 Beer and Brewery creation
 Only Beer and Brewery data parsing occurs in this program.
 When the parsing is done, we call the createBeerObject and createBreweryObject 
 functions which load the objects in a processing queue in 
 BreweryAndBeerCreationQueue. There Breweries will be created first and 
 then beers will be created. 
 
 Beer and Brewery images
 After each brewery/beer is created, BreweryAndBeerCreation will call
 this class's downloadImageToCoreData function.
 When the images have been downloaded they will be loaded into this class's
 imagesToBeAssignedQueue. Here a timer will fire repeatedly and place all images
 with their respective brewery or beer.

 */

import Foundation
import Alamofire
import CoreData


class BreweryDBClient {
    

    // MARK: Enumerations

    // This is the switch that describes the output of the parsing section
    internal enum APIQueryResponseProcessingTypes {
        // This will produce Beers and Breweries and is called from the Style table
        case BeersFollowedByBreweries
        // This will produce styles it is automatically called.
        case Styles
        // This will produce breweries only and is called when you search on 
        // the All Breweries table
        case Breweries
        // This will produce beers when and is called when any brewery is selected.
        case BeersByBreweryID
    }

    // This is the primary writer in the system to coredata
    fileprivate let breweryAndBeerCreator = BreweryAndBeerCreationQueue()

    fileprivate let imageLinker = ManagedObjectImageLinker()

    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext
    private let backContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.newBackgroundContext()

    // MARK: Variables


    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> BreweryDBClient {
        struct Singleton {
            static var sharedInstance = BreweryDBClient()
        }
        return Singleton.sharedInstance
    }
    

    // MARK: Functions




    // Parse beer data and send to creation queue.
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

    
    // Parse brewery data and send to creation queue.
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
            inImageUrl: breweryDict["images"]?["icon"] as? String ?? "")

        breweryAndBeerCreator.queueBrewery(breweryData)
    }


    private func createURLFromParameters(queryType: APIQueryResponseProcessingTypes,
                                         querySpecificID: String?,
                                         parameters: [String:AnyObject]) -> NSURL {
        /* The url currently takes the form of
         "http://api.brewerydb.com/v2/beers?p=1&format=json&isOrganic=N&withBreweries=Y&styleId=159&key=8e63b90f589c3b3f2001c5e396f5d300key=&format=json&isOrganic=Y&styleId=1&withBreweries=Y")
        */
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

        return components.url! as NSURL
    }
    
    
    // Query for all breweries
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
                    completion(false, "Failed Request Please try again")
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed Request Please try again")
                    return
                }
                
                guard let numberOfPages = responseJSON["numberOfPages"] as! Int? else {
                    completion(false, "No results")
                    return
                }

                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()
                
                for i in 1...numberOfPages {
                    methodParameters[Constants.BreweryParameterKeys.Page] = i as AnyObject
                    let outputURL : NSURL = self.createURLFromParameters(queryType: theOutputType,
                                                                         querySpecificID: nil,
                                                                         parameters: methodParameters)
                    // When all dispatch groups leave their processing
                    // We will get notified with the group.notify.
                    // Currently this means after we get results for every page 
                    // from BreweryDb
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
                    completion(true, "downloadAllBreweries All Pages Submitted To BreweryDB for processing All Pages Processed")
                }
        }
        return
    }
    
    
    // Query for breweries that offer a certain style.
    internal func downloadBeersAndBreweriesBy(styleID : String,
                                              completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        var methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject,
            Constants.BreweryParameterKeys.Page : "1" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                                        querySpecificID: nil,
                                                        parameters: methodParameters)

        Alamofire.request(outputURL.absoluteString!).responseJSON {
            response in
            guard response.result.isSuccess else {
                completion(false, "Failed Request Please try again")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completion(false, "Failed Request Please try again")
                return
            }
            guard let numberOfPagesInt = responseJSON["numberOfPages"] as! Int? else {
                completion(false, "No results")
                return
            }
            guard (responseJSON["totalResults"] as! Int?) != nil else {
                completion(false, "No results")
                return
            }

            // Asynchronous page processing
            let queue : DispatchQueue = DispatchQueue.global(qos: .utility)
            let group : DispatchGroup = DispatchGroup()
            for p in 1...numberOfPagesInt {
                methodParameters[Constants.BreweryParameterKeys.Page] = p as AnyObject
                let outputURL : NSURL = self.createURLFromParameters(queryType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                                                     querySpecificID: nil,
                                                                     parameters: methodParameters)
                group.enter()
                queue.async(group: group) {
                print("Group entered \(p)")
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
                            // Relying on the group pushed down to the parse request
                            // doesn't work all the time
                    } //Outside alamo but inside async
                    print("Let me leave group \(p)")
                    group.leave()
                } //Outside queue.async
            }  // Outside for loop
            
            group.notify(queue: queue) {
                print("Group notify")
                completion(true, "All Pages Submitted Processed DownloadBeerAndBreweriesByStyleID")
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
                completionHandler(false, "Failed Request Please try again")
                return
            }
            guard let responseJSON = response.result.value as? [String:AnyObject] else {
                completionHandler(false,"Failed Request Please try again")
                return
            }
            // Note: This request does not return "totalResults" or 
            // "numberOfPages", so don't check for it
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
                
                // Processing Pages
                let queue : DispatchQueue = DispatchQueue.global()
                let group = DispatchGroup()
                
                for i in 1...numberOfPages {
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
                                    completion(false, "Failed Request Please try again")
                                    return
                                }
                                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                                    completion(false, "Failed Request Please try again")
                                    return
                                }
                                self.parse(response: responseJSON as NSDictionary,
                                           querySpecificID:  nil,
                                           outputType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                           completion: completion,
                                           group: group)
                                group.leave()
                        }
                    }
                }
                group.notify(queue: queue){
                    completion(true, "All Pages Processed downloadBeersByName")
                }
        }
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
                print(response)
                guard response.result.isSuccess else {
                    completion(false, "Failed Request Please try again")
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    completion(false, "Failed Request Please try again")
                    return
                }
                
                guard let numberOfPages = responseJSON["numberOfPages"] as! Int? else {
                    completion(false, "No results")
                    return
                }
                guard (responseJSON["totalResults"] as! Int?) != nil else {
                    completion(false, "No results")
                    return
                }

                // Asynchronous page processing
                let queue : DispatchQueue = DispatchQueue.global()
                let group : DispatchGroup = DispatchGroup()

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
                                    completion(false, "Failed Request Please try again")
                                    return
                                }
                                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                                    completion(false, "Failed Request Please try again")
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
    internal func downloadImageToCoreData( forType: ImageDownloadType,
                                           aturl: NSURL,
                                           forID: String) {
        guard aturl.absoluteString != "" else {
            // There must be a url
            return
        }
        let session = URLSession.shared
        let task = session.dataTask(with: aturl as URL){
            (data, response, error) -> Void in
            guard error == nil else {
                // Keep trying to download the image on a failure.
                self.downloadImageToCoreData(forType: forType, aturl: aturl, forID: forID)
                return
            }
            guard data != nil else {
                // Data not there
                return
            }

            // Package the data and queue it up for linking
            let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!)! as NSData

            // Send linking job out for processing.
            self.imageLinker.queueLinkJob(moID: forID, moType: forType, data: outputData)
        }
        task.resume()
    }


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
            // Save the multiple styles from the server
            // We must have data to process else escape
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "No styles data" )
                return
            }
            // Check to see if the style is already in coredata then skip, else add
            let request = NSFetchRequest<Style>(entityName: "Style")
            request.sortDescriptors = []

            readOnlyContext?.perform {
                // Creating these in the readOnlyContext because they 
                // Are critically needed in the UI
                for aStyle in styleArrayOfDict {
                    print("there are this many styles:\(styleArrayOfDict.count)")
                    let localId = aStyle["id"]?.stringValue
                    let localName = aStyle["name"]
                    do {
                        request.predicate = NSPredicate(format: "id = %@", localId!)
                        let results = try self.readOnlyContext?.fetch(request)

                        // if the style is already in coredata skip it
                        if (results?.count)! > 0 {
                            continue
                        } else {
                            print ("No style found")
                        }
                    } catch {
                        completion!(false, "Failed Reading Styles from database")
                        return
                    }

                    // When a New Style, creates a new style
                    _ = Style(id: localId!,
                              name: localName! as! String,
                              context: self.readOnlyContext!)
                    do {
                        try self.readOnlyContext?.save()
                    } catch _ {
                        fatalError("Fatal Error Writing to CoreData")
                    }
                }
                completion!(true,"Completed processing styles")
                return
            }
            break
            
            
        case .Breweries:
            // If there are no pages means there is nothing to process.
            guard (response["numberOfPages"] as? Int) != nil else {
                completion!(false, "No results returned")
                return
            }

            //Unable to parse Brewery Failed to extract data
            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "Network error please try again")
                return
            }

            // This for loop will asynchronousy launch brewery creation.
            breweryLoop: for breweryDict in breweryArray {
                // Can't build a brewery location if no location exist skip brewery
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
            createBeerLoop: for beer in beerArray {

                // This beer has no style id skip it
                guard beer["styleId"] != nil else {
                    continue createBeerLoop
                }

                createBeerObject(beer: beer, brewerID: querySpecificID!) {
                    (Beer) -> Void in
                }
            }
            break
        }
    }
}


