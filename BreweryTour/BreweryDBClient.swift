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
 Processing requests thru the BreweryDBClientProtocol
 Since multiple pages of data exist for almost every query, we have to call for
 each page individually. We have put thes in a DispatchGroup so when all
 requests for pages have been sent to the BreweryDB. We return a call to the UI,
 that we successfully sent all the requests.

 Beer and Brewery creation
 Only Beer and Brewery data parsing occurs in this program.
 When the parsing is done, we call the createBeerObject and createBreweryObject 
 functions which load the objects in a processing queue in 
 BreweryAndBeerCreationQueue. There Breweries will be created first and 
 then beers will be created. 
 Duplicate beers and breweries will be dealt with in the CreationQueue.

 
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

protocol BreweryDBClientProtocol {

    func isBreweryAndBeerCreationRunning() -> Bool

    func downloadAllBreweries(completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) 

    // Query for breweries that offer a certain style.
    func downloadBeersAndBreweriesBy(styleID : String,
                                              completion: @escaping (_ success: Bool, _ msg: String?) -> Void )
    // Download all beers from a Brewery
    func downloadBeersBy(brewery: Brewery,
                                  completionHandler: @escaping ( _ success: Bool, _ msg: String? ) -> Void )

    // Query for beers with a specific name
    func downloadBeersBy(name: String,
                         completion: @escaping (_ success : Bool , _ msg : String? ) -> Void )

    // Downloads Beer Styles
    func downloadBeerStyles(completionHandler: @escaping (_ success: Bool,_ msg: String?) -> Void )
    // Query for breweries with a specific name

    func downloadBreweryBy(name: String, completion: @escaping (_ success: Bool, _ msg: String?) -> Void )

    // Download images in the background for a brewery
    func downloadImageToCoreData( forType: ImageDownloadType,
                                  aturl: NSURL,
                                  forID: String)
}


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

    // This object links beers and breweries to their images.
    fileprivate let imageLinker = ManagedObjectImageLinker()

    // This managed object context is fetching information.
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
                                     locationDict locDict: [String:AnyObject],
                                     brewersID: String,
                                     style: String?,
                                     completion: @escaping (_ out : Brewery) -> () ) {
        let breweryData = BreweryData(
            inName: breweryDict["name"] as! String,
            inLatitude: (locDict["latitude"]?.description)!,
            inLongitude: (locDict["longitude"]?.description)!,
            inUrl: (locDict["website"] as! String? ?? ""),
            open: (locDict["openToPublic"] as! String == "Y") ? true : false,
            inId: brewersID,
            inImageUrl: breweryDict["images"]?["icon"] as? String ?? "",
            inStyleID: style)

        breweryAndBeerCreator.queueBrewery(breweryData)
    }


    private func createURLFromParameters(queryType: APIQueryResponseProcessingTypes,
                                         querySpecificID: String?,
                                         parameters: [String:AnyObject]) -> NSURL {
        /* 
         The url currently takes the form of
         "http://api.brewerydb.com/v2/beers?p=1&format=json&withBreweries=Y&styleId=159&key=8e63b90f589c3b3f2001c5e396f5d300key=&format=json&isOrganic=Y&styleId=1&withBreweries=Y"
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

    // Parse results into objects
    private func parse(response : NSDictionary,
                       querySpecificID : String?,
                       outputType: APIQueryResponseProcessingTypes,
                       completion: (( (_ success :  Bool, _ msg: String?) -> Void )?),
                       group: DispatchGroup? = nil){

        // Process every query type accordingly
        switch outputType {


        case APIQueryResponseProcessingTypes.BeersFollowedByBreweries:

            guard let beerArray = response["data"] as? [[String:AnyObject]] else {// No beer data was returned, exit
                completion!(false, "Failed Request No data was returned")
                return
            }

            createBeerLoop: for beer in beerArray {

                guard let breweriesArray = beer["breweries"], // Must have brewery information
                    beer["styleId"] != nil // Must have a style id
                    else {
                        continue createBeerLoop
                }

                breweryLoop: for brewery in (breweriesArray as! Array<AnyObject>) {

                    guard let breweryDict = brewery as? [String : AnyObject],
                        let locationInfo = breweryDict["locations"] as? NSArray,
                        let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary, // Must have information
                        locDic["openToPublic"] as! String == "Y", // Must be open to the public
                        locDic["longitude"] != nil, // Must have a location
                        locDic["latitude"] != nil,
                        locDic["id"]?.description != nil  // Must have an id to link
                        else {
                            continue createBeerLoop
                    }

                    guard breweryDict["name"] != nil else { // Sometimes the breweries have no name, making it useless
                        continue breweryLoop
                    }

                    let brewersID = (locDic["id"]?.description)! // Make one brewersID for both beer and brewery

                    // Send to brewery creation process
                    self.createBreweryObject(breweryDict: breweryDict,
                                             locationDict: locDic,
                                             brewersID: brewersID,
                                             style: (beer["styleId"] as! NSNumber).description) {
                                                (Brewery) -> Void in
                    }

                    // Send to beer creation process
                    self.createBeerObject(beer: beer, brewerID: brewersID) {
                        (Beer) -> Void in
                    }

                    // Process only one brewery per beer
                    break breweryLoop

                } //  end of brewery loop
            } // end of beer loop
            break


        case .Styles:

            // Saves the multiple styles from the server
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else { // We must have data to process else escape
                completion!(false, "No styles data" )
                return
            }

            // Check to see if the style is already in coredata then skip, else add
            let request = NSFetchRequest<Style>(entityName: "Style")
            request.sortDescriptors = []

            readOnlyContext?.perform {

                // Creating these in the readOnlyContext because they
                // are critically needed in the UI

                for aStyle in styleArrayOfDict {
                    let localId = aStyle["id"]?.stringValue

                    do { // Find existing style then skip.
                        request.predicate = NSPredicate(format: "id = %@", localId!)
                        let results = try self.readOnlyContext?.fetch(request)

                        // if the style is already in coredata skip it
                        guard (results?.count)! == 0 else {
                            continue
                        }

                    } catch {
                        completion!(false, "Failed Reading Styles from database")
                        return
                    }

                    let localName = aStyle["name"]

                    // Creates a new style
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

            // Unable to parse Brewery Failed to extract data
            guard let breweryArray = response["data"] as? [[String:AnyObject]] else {
                completion!(false, "Network error please try again")
                return
            }

            breweryLoop: for breweryDict in breweryArray {

                // Can't build a brewery location if no location exist skip brewery
                guard let locationInfo = breweryDict["locations"] as? NSArray,
                    let locDic : [String:AnyObject] = locationInfo[0] as? Dictionary,
                    let openToPublic = locDic["openToPublic"],
                    openToPublic as! String == "Y",
                    locDic["longitude"] != nil,
                    locDic["latitude"] != nil,
                    breweryDict["name"] != nil // Without name can't store.
                    else {
                        continue breweryLoop
                }

                // Make one brewers id
                let brewersID = (locDic["id"]?.description)!

                createBreweryObject(breweryDict: breweryDict,
                                    locationDict: locDic,
                                    brewersID: brewersID,
                                    style: nil) { // There is no style to pull in when looking for breweries only.
                                        (thisbrewery) -> Void in
                }
            } // end of breweryLoop
            completion!(true, "Success")
            break


        case .BeersByBreweryID:
            // Since were are querying by brewery ID we can be guaranteed that
            // the brewery exists and we can use the querySpecificID!.
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


    // MARK: - BreweryDBClientProtocol

    private func genericJSONResponseProcessSuccess(response: DataResponse<Any>) -> Bool {
        guard response.result.isSuccess else {
            return false
        }
        guard (response.result.value as? [String:AnyObject]) != nil else {
            return false
        }
        return true
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

                guard self.genericJSONResponseProcessSuccess(response: response) else {
                    completion(false,"Network failure, please try again later")
                    return
                }
                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

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

                                guard self.genericJSONResponseProcessSuccess(response: response) else {
                                    completion(false,"Network failure, please try again later")
                                    return
                                }
                                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

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
            guard self.genericJSONResponseProcessSuccess(response: response) else {
                completion(false,"Network failure, please try again later")
                return
            }
            let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

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
                Alamofire.request(outputURL.absoluteString!)
                        .responseJSON {
                            response in

                            guard self.genericJSONResponseProcessSuccess(response: response) else {
                                completion(false,"Network failure, please try again later")
                                return
                            }
                            let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]
                            
                            self.parse(response: responseJSON as NSDictionary,
                                       querySpecificID:  styleID,
                                       outputType: APIQueryResponseProcessingTypes.BeersFollowedByBreweries,
                                       completion: completion,
                                       group: group)

                    } //Outside alamo but inside async
                    group.leave()
                } //Outside queue.async
            }  // Outside for loop
            
            group.notify(queue: queue) {
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
            guard self.genericJSONResponseProcessSuccess(response: response) else {
                completionHandler(false,"Network failure, please try again later")
                return
            }
                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

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

                guard self.genericJSONResponseProcessSuccess(response: response) else {
                    completion(false,"Network failure, please try again later")
                    return
                }
                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]
                
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

                                guard self.genericJSONResponseProcessSuccess(response: response) else {
                                    completion(false,"Network failure, please try again later")
                                    return
                                }
                                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

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

            guard self.genericJSONResponseProcessSuccess(response: response) else {
                completionHandler(false,"Network failure, please try again later")
                return
            }
            let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

            // All the beer styles currently fit on one page may need to change in the future
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

                guard self.genericJSONResponseProcessSuccess(response: response) else {
                    completion(false,"Network failure, please try again later")
                    return
                }
                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]
                
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

                                guard self.genericJSONResponseProcessSuccess(response: response) else {
                                    completion(false,"Network failure, please try again later")
                                    return
                                }
                                let responseJSON: [String:AnyObject] = response.result.value as! [String : AnyObject]

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
        guard aturl.absoluteString != "" else { // Must be a url
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
            if let outputData : NSData = UIImagePNGRepresentation(UIImage(data: data!)!) as NSData? {

                // Send linking job out for processing.
                self.imageLinker.queueLinkJob(moID: forID, moType: forType, data: outputData)
            }


        }
        task.resume()
    }

    // Check is Brewery and Beer creation is still processing things in their queue.
    func isBreweryAndBeerCreationRunning() -> Bool {
        return breweryAndBeerCreator.isBreweryAndBeerCreationRunning()
    }


}

