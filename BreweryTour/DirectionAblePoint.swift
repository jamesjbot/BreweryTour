//
//  DirectionAblePoint.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/25/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
import MapKit
import UIKit

class DirectionAblePoint: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var locationName: String?

    init(annotation: MKAnnotation) {
        coordinate = annotation.coordinate
        title = annotation.title!
        locationName = annotation.subtitle!
        super.init()
    }

    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate

        super.init()
    }


    func createMapItem() -> MKMapItem {
        //let address = [String(CNPostalAddressStreetKey): self.title as! AnyObject]
        let placemark = MKPlacemark(coordinate: self.coordinate)
        //, addressDictionary: //address)

        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = self.title

        return mapItem
    }
}
