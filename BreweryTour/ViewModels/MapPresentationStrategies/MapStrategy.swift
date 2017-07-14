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


    func endSearch() {
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
        breweryLocations = breweryLocations.sorted(by:
            { (brewery1, brewery2) -> Bool in
                // FIXME: Locatins are coming in with nil
                let location1: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery1.latitude!)!), longitude: CLLocationDegrees(Double(brewery1.longitude!)!))
                let location2: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery2.latitude!)!), longitude: CLLocationDegrees(Double(brewery2.longitude!)!))
                return ((targetLocation?.distance(from: location1))! as Double) < ((targetLocation?.distance(from: location2))! as Double)
        })
    }
}
