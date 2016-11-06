//
//  BreweryDBClientConstants.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 11/3/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation

extension BreweryDBClient {
    
    struct Constants {
        struct BreweryDB {
            static let APIScheme = "http"
            static let APIHost = "api.brewerydb.com"
            static let APIPath = "/v2/"
            struct Methods {
                static let Beers = "beers"
                static let Breweries = "breweries"
                static let Brewery = "brewery"
                static let Styles = "styles"
                static let Beer = "beer"
            }
        }
        
        struct BreweryParameterKeys {
            static let Key = "key"
            static let Format = "format"
            static let Organic = "isOrganic"
            static let StyleID = "styleId"
            static let WithBreweries = "withBreweries"
            static let HasImages = "hasImages"
            static let WithLocations = "withLocations"
            static let Page = "p"
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
