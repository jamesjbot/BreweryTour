//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import Alamofire


struct BreweryLocation {
    var latitude : String?
    var longitude : String?
    var url : String?
    var name : String
}

class BreweryDBClient {
    
    // MARK: Enumerations
    
    internal enum APIQueryTypes {
        case Beers
    }
    
    // MARK: Variables
    
    internal var breweryLocationsArray = [BreweryLocation]()
    
    // MARK: Singleton Implementation
    
    private init(){}
    internal class func sharedInstance() -> BreweryDBClient {
        struct Singleton {
            static var sharedInstance = BreweryDBClient()
        }
        return Singleton.sharedInstance
    }
    // MARK: Functions
    internal func downloadBeerStyles(){
        
        
    }
    
    internal func downloadBreweries(){
        //        let methodParameters = [
        //            Constants.BreweryParameterKeys.Key.Method : Constants.BreweryParameterValues.SearchMethod,
        //            Constants.BreweryParameterKeys.Format : Constants.BreweryParameterValues.FormatValue,
        //            Constants.FlickrParameterKeys.BoundingBox : boundingboxConstruct(),
        //            Constants.FlickrParameterKeys.SafeSearch : Constants.FlickrParameterValues.UseSafeSearch,
        //            Constants.FlickrParameterKeys.Extras : Constants.FlickrParameterValues.MediumURL,
        //            Constants.FlickrParameterKeys.Format : Constants.FlickrParameterValues.ResponseFormat,
        //            Constants.FlickrParameterKeys.NoJSONCallback : Constants.FlickrParameterValues.DisableJSONCallback,
        //            Constants.FlickrParameterKeys.Lat : pinLocation!.latitude!,
        //            Constants.FlickrParameterKeys.Lon : pinLocation!.longitude!
        //        ]
        //let outputURL : NSURL = createURLFromarameters()
        print("Attempting to download")
        //Alamofire.request("http://api.brewerydb.com/v2/categories/?key=\(Constants.BreweryParameterValues.APIKey)")
        // Query for beers with certain style.
        Alamofire.request("http://api.brewerydb.com/v2/beers?key=\(Constants.BreweryParameterValues.APIKey)&format=json&isOrganic=Y&styleId=1&withBreweries=Y")
            .responseJSON { response  in
                guard response.result.isSuccess else {
                    print("failed")
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
        print("Repeat \(#line)")
        switch asQueryType {
        case APIQueryTypes.Beers:
            // The Key in this dictionary are [status,data,numberOfPages,currentPage,totalResults]
            //print(response["data"])
            let beerArray = response["data"] as? [[String:AnyObject]]
            // Array of dictionaries
            //print(type(of: beerArray))

            for beer in beerArray! {
                //print("Repeat from \(#line) beerArray")
                //print(beer)
                let breweryInfo = beer["breweries"] as! NSArray
                //print(type(of: breweryInfo))
                //print(breweryInfo)
                //print(breweryInfo.count)
                for (i,element) in breweryInfo.enumerated() {
                    //print("Another brewery")
                    let brewDict = element as! NSDictionary
                    //print(brewDict["isOrganic"])
                    //print(type(of: element))
                    ///print("Element \(i) in brewerinfo:\(element)")
                    for (k,v) in brewDict {
                        //print("In brewDict k:\(k) v:\(v)")
                    }
                    
                    if let images = brewDict["images"] as? [String : AnyObject] {
                        //print("Image to use\(images["squareMedium"])")
                    }

                    let locationInfo = brewDict["locations"] as! NSArray
                    // If i want to use company info I may need to change the dictionary from String String
                    let locDic = locationInfo[0] as! [String : AnyObject]
                    if locDic["openToPublic"] as! String == "Y" {
                        //print("it's open")
                        breweryLocationsArray.append(BreweryLocation(
                                latitude: locDic["latitude"]?.description,
                                longitude: locDic["longitude"]?.description,
                                url: locDic["website"] as! String?,
                                name: brewDict["name"] as! String))
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
            
        default:
            break
        }
    }
    
    internal func getBreweries() -> [BreweryLocation]{
        return breweryLocationsArray
    }
    
    enum QueryTypes {
        case Beers
    }
}

extension BreweryDBClient {
    
    private func createURLFromParameters(paramenters: [String:AnyObject]) -> NSURL {
        let components = NSURLComponents()
        components.scheme = Constants.Brewery.APIScheme
        components.host = Constants.Brewery.APIHost
        components.path = Constants.Brewery.APIPath
        components.queryItems = [NSURLQueryItem]() as [URLQueryItem]?
        
        for (key, value) in paramenters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems?.append(queryItem as URLQueryItem)
        }
        return components.url! as NSURL
    }
    
    struct Constants {
        struct Brewery {
            static let APIScheme = "http"
            static let APIHost = "api.brewerydb.com"
            static let APIPath = "/services/rest/v2"
        }
        
        struct BreweryParameterKeys {
            static let Key = "key"
            static let Format = "format"
            static let Organic = "isOrganic"
            static let StyleID = "styleID"
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
