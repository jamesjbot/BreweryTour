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
    
    internal enum APIQueryTypes {
        case Beers
        case Styles
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
    
    internal func downloadBeerStyles(completionHandler: @escaping (_ success: Bool) -> Void ){
        let methodParameter : [String:AnyObject] = [Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject
]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryTypes.Styles,parameters: methodParameter)
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
            self.parse(response: responseJSON as NSDictionary, asQueryType: APIQueryTypes.Styles)
            completionHandler(true)
            return
        }
    }
    
    
    // Query for breweries that offer a certain style.
    internal func downloadBreweries(styleID : String, isOrganic : Bool , completion: @escaping (_ success: Bool)-> Void ) {
        let methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.Organic : (isOrganic ? "Y" : "N") as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryTypes.Beers,parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            .responseJSON { response  in
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
                self.parse(response: responseJSON as NSDictionary, asQueryType: APIQueryTypes.Beers)
                completion(true)
                return
        }
    }
    
    
    private func parse(response : NSDictionary, asQueryType: APIQueryTypes){
        switch asQueryType {
        case APIQueryTypes.Beers:
            // The Keys in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            // Extracting beer data array of dictionaries
            guard let beerArray = response["data"] as? [[String:AnyObject]] else {
                print("Failed to extract data")
                return
            }
            
            // Clear out previous query from background ManagedObjectContext
            for i in (coreDataStack?.backgroundContext.registeredObjects)! {
                coreDataStack?.backgroundContext.delete(i)
            }
            do {
                try coreDataStack?.backgroundContext.save()
            } catch {
                
            }

            for beer in beerArray {
                print("---------------------NextBeer---------------------")
                // Every beer is a dictionary; that also has an array of brewery information
                
                // Create the coredata object for each beer
                // which will include name, description, availability, brewery name, styleID
                //print("beer:\(beer["name"])")
//                print("beerDescription:\(beer["description"])")
//                print("labels:\(beer["labels"])")
//                print("id:\(beer["id"])")
//                print(coreDataStack?.mainContext)
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
                    let icon = images["icon"] as! String?,
                    let medium = images["medium"] as! String?  {
                    thisBeer.imageUrl = medium
                    let queue = DispatchQueue(label: "Images")
                    print("Prior to getting image")
                    queue.async(qos: .utility) {
                        print("Getting images in background")
                        self.downloadImageToCoreData(aturl: NSURL(string: thisBeer.imageUrl!)!, forBeer: thisBeer, updateManagedObjectID: thisBeer.objectID, index: nil)
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
                    print(locDic["latitude"])
                    print(locDic["longitude"])
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
                    
                            let thisBrewery = Brewery(inName: breweryDict["name"] as! String,
                                    latitude: locDic["latitude"]?.description,
                                    longitude: locDic["longitude"]?.description,
                                    url: locDic["website"] as! String?,
                                    open: (locDic["openToPublic"] as! String == "Y") ? true : false,
                                    id: locDic["id"]?.description,
                                    context: (coreDataStack?.backgroundContext)!)
                        print("Brewery object created \(locDic["id"])")
                        // Assign this brewery to this beer
                        thisBeer.brewer = thisBrewery
                            
                        //We might only create the beer if the brewery is open
                    } else {
                        print("Closed to the public")
                    }

                    }
                }
            
            do {
                try coreDataStack?.backgroundContext.save()
            } catch let error {
                fatalError("Saving background error \(error)")
            }
            
            break

        case .Styles:
            // Styles are saved on the persistingContext because they don't change.
            // We must have data to process
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else {
                print("Failed to convert")
                return
            }
            // Create a style object for every beer style
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
        }
    }

    
    // Download images in the background then update Coredata when complete
    internal func downloadImageToCoreData( aturl: NSURL, forBeer: Beer, updateManagedObjectID: NSManagedObjectID, index: NSIndexPath?) {
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
    
    
    private func createURLFromParameters(queryType: APIQueryTypes, parameters: [String:AnyObject]) -> NSURL {
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
        }
        
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        let queryItem : URLQueryItem = NSURLQueryItem(name: Constants.BreweryParameterKeys.Key, value: Constants.BreweryParameterValues.APIKey) as URLQueryItem
        components.queryItems?.append(queryItem)
        
        // Build parameters
        for (key, value) in parameters {
            print(key,value)
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem as URLQueryItem)
        }
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
                static let Styles = "styles"
            }
        }
        
        struct BreweryParameterKeys {
            static let Key = "key"
            static let Format = "format"
            static let Organic = "isOrganic"
            static let StyleID = "styleId"
            static let WithBreweries = "withBreweries"
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
