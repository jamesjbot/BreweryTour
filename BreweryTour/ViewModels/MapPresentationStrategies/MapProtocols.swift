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
import Bond

protocol MapAnnotationProvider {

    var annotations: MutableObservableArray<MKAnnotation> { get set }

    /// Converts breweries to annotations
    func convertBreweryToAnnotation(breweries: [Brewery]) -> [MKAnnotation]

    /// This function is called by the MapAnnotationReceiver to end the current search
    func endSearch() -> (()->())?

    func getBreweries() -> [Brewery]
}


protocol MappableStrategy: MapAnnotationProvider {

    var annotations: MutableObservableArray<MKAnnotation> { set get }
    var parentMapViewController: MapAnnotationReceiver? { set get }
    var targetLocation: CLLocation { set get }

    func sortAsynchronously(_ locations: [Brewery],
                            inRelationTo: CLLocation,
                            completion: @escaping ([Brewery])->() )

    init()

    init(view: MapAnnotationReceiver)
}


// MARK: -

extension MappableStrategy {

    // MARK: Functions
    init() {
        self.init()
    }

    init(view: MapAnnotationReceiver) {
        self.init()
        parentMapViewController = view
    }


    // MARK: Protocol Extension implementation of MapAnnotationProvider functions

    // Converts brewery locations to map annotations
    func convertBreweryToAnnotation(breweries breweryLocations: [Brewery]) -> [MKAnnotation] {
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

    
    // Sort the breweries by distance to targetLocation
    func sortAsynchronously(_ locations: [Brewery],
              inRelationTo mapCenterTarget: CLLocation,
              completion: @escaping ([Brewery])->() ) {
        DispatchQueue.global(qos: .userInteractive).async {
            var breweryLocations = locations
            // If there are less than 2 breweries no need to sort.
            guard breweryLocations.count > 1 else {
                completion(breweryLocations)
                return
            }
            guard self.isAllLocationDataNonNil(in: breweryLocations) else {
                log.error("MapStrategy detected breweries without location data.")
                return
            }
            log.info("MapStrategy.sortLocations() Sorting breweries by positons")
            breweryLocations = breweryLocations.sorted(by:
                { (brewery1, brewery2) -> Bool in
                    let location1: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery1.latitude!)!), longitude: CLLocationDegrees(Double(brewery1.longitude!)!))
                    let location2: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery2.latitude!)!), longitude: CLLocationDegrees(Double(brewery2.longitude!)!))
                    return ((mapCenterTarget.distance(from: location1)) as Double) < ((mapCenterTarget.distance(from: location2)) as Double)
            })

            completion(breweryLocations)
        }

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
