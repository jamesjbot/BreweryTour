//
//  ParserFactory.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

protocol ParserFactoryProtocol {
    func createParser(type: BreweryDBClient.APIQueryResponseProcessingTypes) -> ParserProtocol?
}

class ParserFactory: ParserFactoryProtocol {

    var creationQueue: BreweryAndBeerCreationProtocol?

    var breweryDesigner: BreweryDesignerProtocol?
    var beerDesigner: BeerDesigner?

    internal func set(breweryDesigner: BreweryDesignerProtocol) {
        self.breweryDesigner = breweryDesigner
    }

    internal func set(beerDesigner: BeerDesigner) {
        self.beerDesigner = beerDesigner
    }

    init(withQueue: BreweryAndBeerCreationProtocol) {
        self.creationQueue = withQueue
    }

    func createParser(type: BreweryDBClient.APIQueryResponseProcessingTypes) -> ParserProtocol? {
        switch type {
        case BreweryDBClient.APIQueryResponseProcessingTypes.BeersByBreweryID:
            return BeersByBreweryIDParser(withBeerDesigner: beerDesigner!)

        case BreweryDBClient.APIQueryResponseProcessingTypes.BeersFollowedByBreweries:
            if let breweryD = breweryDesigner, let beerD = beerDesigner {
                return BeersFollowedByBreweriesParser(withBeerDesigner: beerD,
                                                      with: breweryD)
            }
            return nil

        case BreweryDBClient.APIQueryResponseProcessingTypes.Breweries:
            if let bd = breweryDesigner {
                return BreweriesParser(with: bd)
            }
            return nil

        case BreweryDBClient.APIQueryResponseProcessingTypes.Styles:
            return StylesParser()
            
        case BreweryDBClient.APIQueryResponseProcessingTypes.LocationFollowedByBrewery:
            if let bd = breweryDesigner {
                return BreweriesByStateParser(with: bd)
            }
            return nil
        }
    }
}
