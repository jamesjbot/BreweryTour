//
//  MapViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/8/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
import UIKit
import Foundation
import MapKit

class MapViewController : UIViewController {
    
    // MARK: IBOutlet
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Variables
    
    internal var incomingLocations = Set<BreweryLocation>()
    
    internal var greeter : FunctionalProtocol!
    
    // MARK: Functions
    
    override func viewDidLoad(){
        super.viewDidLoad()
        //getDataFromTheModel
        incomingLocations = BreweryDBClient.sharedInstance().breweryLocationsSet
        populateMap()
    }
    
    private func populateMap(){
        var annotations = [MKAnnotation]()
        for i in incomingLocations {
            guard i.latitude != nil && i.longitude != nil else {
                continue
            }
            let aPin = MKPointAnnotation()
            aPin.coordinate = CLLocationCoordinate2D(latitude: Double(i.latitude!)!, longitude: Double(i.longitude!)!)
            aPin.title = i.name
            aPin.subtitle = i.url
            annotations.append(aPin)
        }
        mapView.addAnnotations(annotations)
    }
}

extension MapViewController : MKMapViewDelegate {
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        <#code#>
//    }

    // This format pins (annotations on the map)
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = UIColor.red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let url: URL = URL(string: (view.annotation?.subtitle!)!)!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
}
