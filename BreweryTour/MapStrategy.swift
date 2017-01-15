//
//  MapStrategy.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/14/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import MapKit

class MapStrategy: NSObject {

    // MARK: - Variables

    var mapViewController: MapViewController? = nil
    var breweryLocations: [Brewery] = []
    var targetLocation: CLLocation? = nil


    // MARK: - Functions

    override init() {
    }

    func convertLocationToAnnotation() -> [MKAnnotation] {
        var annotations = [MKAnnotation]()
        for (number,i) in breweryLocations.enumerated() {

            // Sometimes the breweries don't have a location
            guard i.latitude != nil && i.longitude != nil else {
                continue
            }

            let aPin = MKPointAnnotation()
            aPin.coordinate = CLLocationCoordinate2D(latitude: Double(i.latitude!)!, longitude: Double(i.longitude!)!)
            aPin.title = i.name
            aPin.subtitle = i.url
            annotations.append(aPin)
        }
        return annotations
    }


    func sortLocations() {
        breweryLocations = breweryLocations.sorted(by:
            { (brewery1, brewery2) -> Bool in
                let location1: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery1.latitude!)!), longitude: CLLocationDegrees(Double(brewery1.longitude!)!))
                let location2: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery2.latitude!)!), longitude: CLLocationDegrees(Double(brewery2.longitude!)!))
                return ((targetLocation?.distance(from: location1))! as Double) < ((targetLocation?.distance(from: location2))! as Double)
        })

    }



    func sendAnnotationsToMap() {
        // Format the first maximumClosestBreweries for display.
        mapViewController?.updateMap(b: convertLocationToAnnotation())
    }


}