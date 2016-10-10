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
            let a = MKPointAnnotation()
            a.coordinate = CLLocationCoordinate2D(latitude: Double(i.latitude!)!, longitude: Double(i.longitude!)!)
            annotations.append(a)
        }
        mapView.addAnnotations(annotations)
    }
    
    
}
