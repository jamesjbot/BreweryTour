//
//  BreweryDBClient.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/7/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import Alamofire

class BreweryDBClient {

    func downloadBeerTypes(){
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
                print(response)
        return
        }
        
//        parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! NSDictionary
    }
    
    func parseData(){
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
        }
        
        struct BreweryParameterValues {
            static let APIKey = "8e63b90f589c3b3f2001c5e396f5d300"
            static let FormatValue = "json"
        }
    }
}
