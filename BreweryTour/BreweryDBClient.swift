//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import Alamofire


struct BreweryLocation : Hashable {
    var latitude : String?
    var longitude : String?
    var url : String?
    var name : String
    var hashValue: Int {
        get {
            return ("\(latitude)\(longitude)").hashValue
        }
    }
    static func ==(lhs: BreweryLocation, rhs: BreweryLocation) -> Bool {
        return (lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude)
    }
}

class BreweryDBClient {
    
    // MARK: Enumerations
    
    internal enum APIQueryTypes {
        case Beers
        case Styles
    }
    
    // MARK: Variables
    
    internal var breweryLocationsSet : Set<BreweryLocation> = Set<BreweryLocation>()
    internal var styleNames = [style]()
 
    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> BreweryDBClient {
        struct Singleton {
            static var sharedInstance = BreweryDBClient()
        }
        return Singleton.sharedInstance
    }
    
    // MARK: Functions
    internal func isReadyWithBreweryLocations() -> Bool {
        return breweryLocationsSet.count > 0
    }
    
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
    internal func downloadBreweries(styleID : String, isOrganic : Bool ){
        let methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatJSON as AnyObject,
            Constants.BreweryParameterKeys.Organic : (isOrganic ? "Y" : "N") as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: APIQueryTypes.Beers,parameters: methodParameters)
        Alamofire.request(outputURL.absoluteString!)
            //Alamofire.request("http://api.brewerydb.com/v2/beers?key=\(Constants.BreweryParameterValues.APIKey)&format=json&isOrganic=Y&styleId=1&withBreweries=Y")
            .responseJSON { response  in
                guard response.result.isSuccess else {
                    print("failed \(response.request?.url)")
                    return
                }
                guard let responseJSON = response.result.value as? [String:AnyObject] else {
                    print("Invalid tag informatiion")
                    return
                }
                self.parse(response: responseJSON as NSDictionary, asQueryType: APIQueryTypes.Beers)
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
            for beer in beerArray {
                // Every beer is a dictionary; that also has an array of brewery information
                
                // Create the coredata object for each beer
                // which will include name, description, availability, brewery name, styleID
                print("beer:\(beer["name"])")
                print("beerDescription:\(beer["description"])")
                print("labels:\(beer["labels"])")
                print("available:\((beer["available"]as?NSDictionary)?["description"])")
                //Beer(name:, beerDescription: <#T##String#>, availability: <#T##String#>, style: <#T##String#>, context: <#T##NSManagedObjectContext#>)
                print("id:\(beer["id"])")
                let breweriesArray = beer["breweries"] as! NSArray
                for brewery in breweriesArray {
                    // The brewery dictionary
                    let breweryDict = brewery as! NSDictionary
                    //                    for (k,v) in breweryDict {
                    //                        //print("In brewDict k:\(k) v:\(v)")
                    //                    }
                    
                    // TODO Save Icons for display
                    if let images = breweryDict["images"] as? [String : AnyObject] {
                    }
                    
                    guard let locationInfo = breweryDict["locations"] as? NSArray else {
                        continue
                    }
                    
                    // TODO Check other information that may be useful for customer
                    let locDic = locationInfo[0] as! [String : AnyObject]
                    // We can't visit a brewery if it's not open to the public
                    if locDic["openToPublic"] as! String == "Y" {
                        breweryLocationsSet.insert(
                            BreweryLocation(
                                latitude: locDic["latitude"]?.description,
                                longitude: locDic["longitude"]?.description,
                                url: locDic["website"] as! String?,
                                name: breweryDict["name"] as! String))
                    }
                    // TODO pull out some other useful information such as website
                    //
                    //let image = breweryInfo["images"]
                    //let location = breweryInfo["locations"] as! [String:AnyObject]
                    //            if location["openToPublic"] as! String == "Y" {
                    //                    breweryLocationsArray.append(BreweryLocation(latitude: location["latitude"] as! String, longitude: location["longitude"] as! String))
                }
            }
            break

        case .Styles:
            guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else {
                print("Failed to convert")
                return
            }
            for aStyle in styleArrayOfDict {
                let localId = aStyle["id"]?.stringValue!
                let localName = aStyle["name"]
                styleNames.append(style(id: localId!  , longName: localName as! String))
            }
            break
        }
    }
    
    struct style {
        var id : String
        var longName : String
    }
    
    internal func getBreweries() -> Set<BreweryLocation>{
        return breweryLocationsSet
    }
    
    private func createURLFromParameters(queryType: APIQueryTypes, parameters: [String:AnyObject]) -> NSURL {
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
