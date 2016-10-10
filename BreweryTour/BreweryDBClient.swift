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
    
    internal func downloadBeerStyles(){
        let methodParameter : [String:AnyObject] = [:]
        let outputURL : NSURL = createURLFromParameters(queryType: QueryTypes.Beers,parameters: methodParameter)
        Alamofire.request(outputURL.absoluteString!).responseJSON(){ response in
            guard response.result.isSuccess else {
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
    
    // Query for breweries that offer a certain style.
    internal func downloadBreweries(styleID : String, isOrganic : Bool ){
        let methodParameters  = [
            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatValue as AnyObject,
            Constants.BreweryParameterKeys.Organic : (isOrganic ? "Y" : "N") as AnyObject,
            Constants.BreweryParameterKeys.StyleID : styleID as AnyObject,
            Constants.BreweryParameterKeys.WithBreweries : "Y" as AnyObject
        ]
        let outputURL : NSURL = createURLFromParameters(queryType: QueryTypes.Beers,parameters: methodParameters)
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
                    
                    let locationInfo = breweryDict["locations"] as! NSArray
                    
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
            break
            
            
        default:
            break
        }
    }
    
    internal func getBreweries() -> Set<BreweryLocation>{
        return breweryLocationsSet
    }
    
    enum QueryTypes {
        case Beers
    }
    
    private func createURLFromParameters(queryType: QueryTypes, parameters: [String:AnyObject]) -> NSURL {
        let components = NSURLComponents()
        components.scheme = Constants.BreweryDB.APIScheme
        components.host = Constants.BreweryDB.APIHost
        switch queryType {
        case .Beers:
            components.path = Constants.BreweryDB.APIPath + Constants.BreweryDB.Methods.Beers
            break
        default:
            break
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
            static let FormatValue = "json"
        }
        
        struct BreweryLocation {
            var latitude : String
            var longitude : String
        }
    }
}
