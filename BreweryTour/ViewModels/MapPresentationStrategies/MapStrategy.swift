//
//  MapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
/*
    The base class for map strategies, provides basic functions for subclasses.
 */

import Foundation
import MapKit
import SwiftyBeaver

protocol MapAnnotationProvider {
    // converts breweries to annotations
    func convertLocationToAnnotation() -> [MKAnnotation]
    func endSearch()
    func sendAnnotationsToMap()
}


class MapStrategy: NSObject, MapAnnotationProvider {

    // MARK: - Variables

    var breweryLocations: [Brewery] = []
    var parentMapViewController: MapViewController? = nil
    var targetLocation: CLLocation? = nil


    // MARK: - Functions

    // Converts brewery locations to map annotations
    func convertLocationToAnnotation() -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        for breweryLocation in breweryLocations {

            // Sometimes the breweries don't have a location
            guard breweryLocation.latitude != nil && breweryLocation.longitude != nil else {
                continue
            }

            let aPin = MKPointAnnotation()
            aPin.coordinate = CLLocationCoordinate2D(latitude: Double(breweryLocation.latitude!)!,
                                                     longitude: Double(breweryLocation.longitude!)!)
            aPin.title = breweryLocation.name
            aPin.subtitle = breweryLocation.url
            annotations.append(aPin)
        }
        return annotations
    }


    internal func endSearch() {
        fatalError("You must override endSearch()!!!")
        // Dummy stub for BreweryMapStrategy
        // StyleMapStrategy will override it's implementation
    }


    func sendAnnotationsToMap() {
        // Format the first maximumClosestBreweries for display.
        parentMapViewController?.updateMap(withAnnotations: convertLocationToAnnotation())
    }

    
    // Sort the breweries by distance to targetLocation
    func sortLocations() {
        // If there are less than 2 breweries no need to sort.
        guard breweryLocations.count > 1 else {
            return
        }
        guard isAllLocationDataNonNil(in: breweryLocations) else {
            SwiftyBeaver.error("MapStrategy detected breweries without location data.")
            return
        }
        SwiftyBeaver.info("MapStrategy.sortLocations() Sorting breweries by positons")
        breweryLocations = breweryLocations.sorted(by:
            { (brewery1, brewery2) -> Bool in
                SwiftyBeaver.verbose("MapStrategy within the brewery sorting closures working on \(breweryLocations.count) breweries")
                let location1: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery1.latitude!)!), longitude: CLLocationDegrees(Double(brewery1.longitude!)!))
                let location2: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery2.latitude!)!), longitude: CLLocationDegrees(Double(brewery2.longitude!)!))
                return ((targetLocation?.distance(from: location1))! as Double) < ((targetLocation?.distance(from: location2))! as Double)
        })
    }


    /// Checks whether all latitudes and longitudes in data is present
    ///
    /// - parameters:
    ///     - locations: An array of breweries
    /// - returns:
    ///     - `true` if all location data present
    private func isAllLocationDataNonNil(in locations: [Brewery]) -> Bool {
        for location in locations {
            if location.longitude == nil || location.latitude == nil {
                return false
            }
        }
        return true
    }
}
