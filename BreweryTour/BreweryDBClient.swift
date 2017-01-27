//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This is the api driver, that makes all the requests to the breweryDB
 This will download and send to parsing all the data for the system.

 Internals
 This explains the processing of search requests thru the BreweryDBClientProtocol
 Multiple pages of data exist for almost every query, we have to call for
 each page individually and asyncrhronously for speed. 
 We put these requests in a DispatchGroup so when all
 requests for pages have been sent to the BreweryDB, we return a call to the UI,
 informing the user that we've successfully sent out all the requests.
 This messaging is accomplished thru the group.notify.
 Parsing occurs for every returned request with the appropriate parser.

 Beer and Brewery creation
 Only Beer and Brewery download requests are handled in this program.
 We pass parsing to their respective parser. From there, the parsers will call
 the beer or brewery Designers to package up the respective data and send it to
 BreweryAndBeerCreationQueue for processing.
 There Breweries will be created first and then beers will be created.
 Duplicate beers and breweries will be dealt with in the CreationQueue.
 
 Beer and Brewery images
 After each brewery/beer is created, BreweryAndBeerCreation will call
 this class's downloadImageToCoreData function.
 When the images have been downloaded they will be loaded into the class's
 ManagedObjectImageLinker class. There a timer will fire repeatedly and place all images
 with their respective brewery or beer.
 */

import Foundation
import Alamofire
import CoreData

protocol BreweryDBClientProtocol {

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


    // Download brewerie by location
    func downloadBreweries(byState: String,
                             completion: @escaping (_ success: Bool, _ msg: String?) -> Void )

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
        // The format of data when search for Breweries by postal code
        case LocationFollowedByBrewery
    }

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

    private func createURLFromParameters(queryType queryProcessingType: APIQueryResponseProcessingTypes,
                                         querySpecificID: String?,
                                         parameters: [String:AnyObject]) -> NSURL {
        /* 
         The url currently takes the form of
         "http://api.brewerydb.com/v2/beers?p=1&format=json&withBreweries=Y&styleId=159&key=8e63b90f589c3b3f2001c5e396f5d300key=&format=json&styleId=1&withBreweries=Y"
        */
        let components = NSURLComponents()
        components.scheme = Constants.BreweryDB.APIScheme
        components.host = Constants.BreweryDB.APIHost

        switch queryProcessingType {
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
        case .LocationFollowedByBrewery:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Locations
            break
        }

        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?

        // Build the other parameters
        for (key, value) in parameters {
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
        let parser: ParserProtocol = ParserFactory.sharedInstance().createParser(type: outputType)
        parser.parse(response: response, querySpecificID: querySpecificID, completion: completion)
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
    

    // Query for all breweries at location
    internal func downloadBreweries(byState: String,
                                    completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) {
        let theOutputType = APIQueryResponseProcessingTypes.LocationFollowedByBrewery
        var methodParameters  = [
            Constants.BreweryParameterKeys.Region : byState as AnyObject,
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
                    completion(true, "download Breweries by location")
                }
        }
        return
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
            if let outputData  = data,
                let image = UIImage(data: outputData),
                let png = UIImagePNGRepresentation(image) {

                // Send linking job out for processing.
                self.imageLinker.queueLinkJob(moID: forID, moType: forType, data: png as NSData)
            }
        }
        task.resume()
    }

}

