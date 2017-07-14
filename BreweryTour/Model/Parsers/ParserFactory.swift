//
//  ParserFactory.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

protocol ParserFactoryProtocol {
    func createParser(type: BreweryDBClient.APIQueryResponseProcessingTypes) -> ParserProtocol
}

class ParserFactory: ParserFactoryProtocol {

    private init(){}
    internal class func sharedInstance() -> ParserFactoryProtocol {
        struct Singleton {
            static var sharedInstance = ParserFactory()
        }
        return Singleton.sharedInstance
    }


    func createParser(type: BreweryDBClient.APIQueryResponseProcessingTypes) -> ParserProtocol {
        switch type {
        case BreweryDBClient.APIQueryResponseProcessingTypes.BeersByBreweryID:
            return BeersByBreweryIDParser()

        case BreweryDBClient.APIQueryResponseProcessingTypes.BeersFollowedByBreweries:
            return BeersFollowedByBreweriesParser()

        case BreweryDBClient.APIQueryResponseProcessingTypes.Breweries:
            return BreweriesParser()

        case BreweryDBClient.APIQueryResponseProcessingTypes.Styles:
            return StylesParser()
            
        case BreweryDBClient.APIQueryResponseProcessingTypes.LocationFollowedByBrewery:
            return BreweriesByStateParser()
        }
    }
}
