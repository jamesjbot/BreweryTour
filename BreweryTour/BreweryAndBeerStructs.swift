//
//  BreweryAndBeerStructs.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation

internal struct BreweryData {
    // Brewery required parameters
    var name: String?
    var latitude: String?
    var longitude: String?
    var url: String?
    var openToThePublic: Bool
    var id: String?
    // Unrequired parametesr
    var favorite: Bool
    var imageUrl: String?
    var brewedbeer: NSSet?
    var styleID: String?
    var completion: ((Brewery) -> Void)?
    internal init(inName: String,
                  inLatitude: String,
                  inLongitude: String,
                  inUrl: String,
                  open: Bool,
                  inId: String,
                  inImageUrl: String?,
                  inStyleID: String?) {
        // Brewery required parameters
        name = inName
        latitude = inLatitude
        longitude = inLongitude
        url = inUrl
        openToThePublic = open
        id = inId
        // Un required parametesr
        favorite = false
        imageUrl = inImageUrl
        styleID = inStyleID
    }
}


internal struct BeerData {
    var availability: String?
    var beerDescription: String?
    var beerName: String?
    var breweryID: String?
    var id: String?
    var imageUrl: String?
    var isOrganic: Bool
    var styleID: String?
    var abv: String?
    var ibu: String?

    init(inputAvailability : String?,
         inDescription : String?,
         inName : String?,
         inBrewerId : String,
         inId : String,
         inImageURL : String?,
         inIsOrganic : Bool,
         inStyle : String?,
         inAbv : String?,
         inIbu : String?) {
        availability = inputAvailability
        beerDescription = inDescription
        beerName = inName
        breweryID = inBrewerId
        id = inId
        imageUrl = inImageURL
        isOrganic = inIsOrganic
        styleID = inStyle
        abv = inAbv!
        ibu = inIbu!
    }
}
