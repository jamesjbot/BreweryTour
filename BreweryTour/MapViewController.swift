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
import CoreLocation
import CoreData

class MapViewController : UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: IBOutlet
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Variables
    
    private var incomingLocations = [Brewery]()
    private var frc : NSFetchedResultsController<Brewery> = NSFetchedResultsController()
    private let locationManager = CLLocationManager()
    
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    
    // MARK: Functions
    // Get the Brewery entries from the database
    private func initializeFetchAndFetchBreweries(){
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        do {
            try incomingLocations = (coreDataStack?.backgroundContext.fetch(request))! as [Brewery]
        } catch {
            fatalError("Failure to query breweries")
        }
        print("Completed getting Breweries")
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        print("View did load called")

        
        // CoreLocation initialization for user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("View will appear called")
        mapView.removeAnnotations(mapView.annotations)
        print("Mapview now has \(mapView.annotations.count) annotations")
        initializeFetchAndFetchBreweries()
        populateMap()
    }
    
    
    // Puts all the Brewery entries on to the map
    private func populateMap(){
        print("populateMapCalled")
        // Remove all the annotation and repopulate
        mapView.removeAnnotations(mapView.annotations)
        var annotations = [MKAnnotation]()
        for i in incomingLocations {
            guard i.latitude != nil && i.longitude != nil else {
                continue
            }
            
            // TODO Check if the point is a favorite is so populate accordingly
            
            let aPin = MKPointAnnotation()
            //print("Last Brewery: \(i)")
            aPin.coordinate = CLLocationCoordinate2D(latitude: Double(i.latitude!)!, longitude: Double(i.longitude!)!)
            aPin.title = i.name
            aPin.subtitle = i.url
            annotations.append(aPin)
        }
        mapView.addAnnotations(annotations)
        _ = mapView.userLocation
    }

    fileprivate func findBreweryInCoreData(by : MKAnnotation) -> Brewery? {
        let lat = by.coordinate.latitude
        let lon = by.coordinate.longitude
        // Iterate across Brewery object on the map
        for i in incomingLocations {
            if i.latitude == (lat.description) && i.longitude == (lon.description) {
                print("found brewery in coredata")
                return i
            }
        }
        return nil
    }


    fileprivate func findBreweryinFavorites(by: MKAnnotation) -> Brewery? {
        let lat = by.coordinate.latitude
        let lon = by.coordinate.longitude
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        let frc = NSFetchedResultsController(fetchRequest: request,
                                                      managedObjectContext: (coreDataStack?.favoritesContext)!,
                                                      sectionNameKeyPath: nil, cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            fatalError()
        }
        for i in frc.fetchedObjects! as [Brewery] {
            if i.latitude == (lat.description) && i.longitude == (lon.description) {
                print("Found brewery in favorites")
                return i
            }
        }
        return nil
    }
    
}


extension MapViewController : MKMapViewDelegate {

    // This formats the pins and calloutAccessory views on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("Formatting of pins and callouts")
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            if pinView?.annotation?.coordinate.latitude == mapView.userLocation.coordinate.latitude
            && pinView?.annotation?.coordinate.longitude == mapView.userLocation.coordinate.longitude {
                pinView!.pinTintColor = UIColor.blue
            } else {
                pinView!.pinTintColor = UIColor.red
            }
            
            // Format annotation callouts here
            pinView?.tintColor = UIColor.red
            //pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            //pinView!.leftCalloutAccessoryView = UIButton(type: .contactAdd)
            pinView?.canShowCallout = true
            let foundBrewery = findBreweryinFavorites(by: annotation)
            if foundBrewery != nil {
                print("Formating pin, \(annotation.title) This brewery has been favorited")
                let temp = UIImage(named: "small_heart_icon.png")
                let localButton = UIButton(type: .contactAdd)
                localButton.setImage(temp, for: .normal)
                pinView?.leftCalloutAccessoryView = localButton
                //(pinView?.leftCalloutAccessoryView as! UIButton).isSelected = true
            } else {
                print("Formatting pin, \(annotation.title) This brewery is unseleted")
                let favoriteBreweryButton = UIButton(type: .contactAdd)
                //favoriteBreweryButton.imageView?.image =  UIImage(named: "small_heart_icon_black_white_line_art.png")
                //let temp = UIImage(named: "small_heart_icon_black_white_line_art.png")
                //favoriteBreweryButton.setImage(temp, for: .normal)
                pinView!.leftCalloutAccessoryView = favoriteBreweryButton
            }
            //pinView!.detailCalloutAccessoryView?.backgroundColor = UIColor.red
            //pinView?.detailCalloutAccessoryView? = (UIButton(type: .roundedRect))
        } else { // TODO why would I not reformat the pinView no matter what
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    // Selecting a Pin, draw the route to this pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        print("didSelectAnnotation")
        // Our location
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: mapView.userLocation.coordinate))
        // The brewerery selected
        let destination = convertToMKMapItemThis(view)
        // Getting plottable directions
        let request = MKDirectionsRequest()
        request.source = origin
        request.destination = destination
        request.requestsAlternateRoutes = true
        request.transportType = .automobile
        let directions = MKDirections(request: request)
        directions.calculate(){
            (response , error ) -> Void in
            if let routeResponse = response?.routes {
                self.removeRouteOnMap()
                // As you can see the response will list many routes, need to sort to just the fastest one
                let quickestRoute : MKRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})[0]
                self.displayRouteOnMap(route: quickestRoute)
            } else {
                print("There are no routes avaialble")
            }
        }
        
    }
    
    
    // Removes all routes from ma
    func removeRouteOnMap(){
        mapView.removeOverlays(mapView.overlays)
    }
    
    
    // Display the route on map
    func displayRouteOnMap(route: MKRoute){
        mapView.add(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(100.0,100.0,100.0,100.0), animated: true)
    }
    
    
    // Utility function to convert annotation coordinates to MKMapitems
    func convertToMKMapItemThis(_ view: MKAnnotationView) -> MKMapItem {
        return MKMapItem(placemark: MKPlacemark(coordinate: (view.annotation?.coordinate)!))
    }
    
    
    // Respond to user taps on the annotation callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        print("THE CALLOUT ACCESSORY \(control)")
        if control == view.leftCalloutAccessoryView {
            print("Left accessory view called")
            // TODO Add to favorites Brewery
            // If this is already a favorite do nothing for now
            let favBrewery = findBreweryinFavorites(by: view.annotation!)
            guard favBrewery == nil else { // A favorite encountered no need to add it again.
                print("This has already been favorited")
                return
            }
            // TODO Prompt the user that they added this brewery to favorites
            // Find the brewery object that belongs to this location
            let targetBrewery : Brewery = findBreweryInCoreData(by: view.annotation!)!
            // Create a brewery object in the favorites
            Brewery(inBrewery: targetBrewery, context: (coreDataStack?.favoritesContext)!)
            // TODO See if we can implement this in coredata
            do {
                
                try coreDataStack?.favoritesContext.save()
                
                DispatchQueue.main.async {
                    (view.leftCalloutAccessoryView as! UIButton).setImage(UIImage(named: "heart_icon.png"), for: .normal)
                    view.setNeedsDisplay()
                    print("Favorite Created")
                }
            } catch {
                
            }
        } else if control == view.rightCalloutAccessoryView {
            print("Right accesory view called")
            // Goto Webpage Information
            if let str : String = (view.annotation?.subtitle)!,
                let url: URL = URL(string: str) {
                        if UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    // Function to performUIUpdates on main queue
    private func performUpdatesOnMain(updates: () -> Void) {

    }
    
    
    // Render the router line
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = UIColor.green.withAlphaComponent(0.5)
            polylineRenderer.lineWidth = 3
        }
        return polylineRenderer
    }
}


// Place the placemark for User's current location

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(locations.last!){
            (placemarks, error) -> Void in
            if let placemarks = placemarks {
                let placemark = placemarks[0]
                // Here is the placemark for the user's location
                let userMapItem = MKMapItem(placemark: MKPlacemark(coordinate: placemark.location!.coordinate, addressDictionary: placemark.addressDictionary as! [String:AnyObject]?))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}

