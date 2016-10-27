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

// I've changed how this gets the breweries to map
// It queries the database for the locations it should display


class MapViewController : UIViewController, NSFetchedResultsControllerDelegate {
    
    // MARK: Debugging
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        return
    }
    
    
    // MARK: IBOutlet
    
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: Variables
    
    // Used to hold the locations we are going to display, loaded from a database query
    private var mappableBreweries = [Brewery]()
    // The query that goes against the database to pull in the brewery location information
    private var frc : NSFetchedResultsController<Brewery> = NSFetchedResultsController()
    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()
    
    fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    
    // MARK: Functions
    
    // Fetch breweries based on style selected.
    // Get the Brewery entries from the database
    private func initializeFetchAndFetchBreweriesSetIncomingLocations(style : Style){
        var request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "styleID = %@", style.id!)
        let results : [Beer]!
        do {
            results = try (coreDataStack?.persistingContext.fetch(request))! as [Beer]
        } catch {
            fatalError()
        }
        print("Found these beers \(results)")
        mappableBreweries = [Brewery]()
        for i in results {
            var breweryRequest = NSFetchRequest<Brewery>(entityName: "Brewery")
            breweryRequest.sortDescriptors = []
            breweryRequest.predicate = NSPredicate(format: "id  %@", i.breweryID!)
            do {
                let b = try (coreDataStack?.persistingContext.fetch(breweryRequest))! as [Brewery]
                print("brewery results\(b.count)")
                if b.count > 1 {fatalError()}
                if !mappableBreweries.contains(b[0]) {
                    mappableBreweries.append(b[0])
                }
            } catch {
                fatalError("Failure to query breweries")
            }
        }
        print("Completed getting Breweries")
    }
    
    
    // Fetch brewery by brewery selected
    private func getBrewery(){
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        // CoreLocation initialization, ask permission to utilize user location
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
        
        let mapViewData = Mediator.sharedInstance().getMapData()
        
        if mapViewData is Style {
            initializeFetchAndFetchBreweriesSetIncomingLocations(style: mapViewData as! Style)
        } else if mapViewData is Brewery {
            mappableBreweries.append(mapViewData as! Brewery)
        } else {
            return
        }
        populateMap()
    }
    
    
    // Puts all the Brewery entries on to the map
    private func populateMap(){
        print("populateMapCalled")
        // Remove all the annotation and repopulate
        mapView.removeAnnotations(mapView.annotations)
        var annotations = [MKAnnotation]()
        for i in mappableBreweries {
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
        // Iterate across Brewery object on the map
        for i in mappableBreweries {
            if i.name == by.title! {
                print("found brewery in coredata")
                return i
            }
            
        }
        return nil
    }
    
    
    fileprivate func findBreweryinFavorites(by: MKAnnotation) -> Brewery? {
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
            if i.name! == by.title! {
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
            if (pinView?.annotation?.title)! == mapView.userLocation.title {
                pinView!.pinTintColor = UIColor.blue
            } else {
                pinView!.pinTintColor = UIColor.red
            }
            
            // Format annotation callouts here
            pinView?.tintColor = UIColor.red
            pinView?.canShowCallout = true
            let foundBrewery = findBreweryinFavorites(by: annotation)
            if foundBrewery?.favorite == true {
                print("Formating pin, \(annotation.title) This brewery has been favorited")
                let temp = UIImage(named: "small_heart_icon.png")?.withRenderingMode(.alwaysOriginal)
                let localButton = UIButton(type: .contactAdd)
                localButton.setImage(temp, for: .normal)
                pinView?.leftCalloutAccessoryView = localButton
            } else {
                print("Formatting pin, \(annotation.title) This brewery is unseleted")
                let favoriteBreweryButton = UIButton(type: .contactAdd)
                let temp = UIImage(named: "small_heart_icon_black_white_line_art.png")?.withRenderingMode(.alwaysOriginal)
                favoriteBreweryButton.setImage(temp, for: .normal)
                pinView!.leftCalloutAccessoryView = favoriteBreweryButton
            }
            
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        } else { // TODO why would I not reformat the pinView no matter what
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    // Selecting a Pin, draw the route to this pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        // Our location
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: mapView.userLocation.coordinate))
        // The brewery selected
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
                // The response will list many routes, need to sort to just the fastest travel time one
                let quickestRoute : MKRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})[0]
                self.displayRouteOnMap(route: quickestRoute)
            } else {
                print("There are no routes avaialble")
            }
        }
        
    }
    
    
    // Removes all routes from map
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
        // Did the user favorite or ask for more information on the brewery
        switch control as UIView {
            
        // Favorite or unfavorite a brewery
        case view.leftCalloutAccessoryView!:
            
            // Find the brewery object that belongs to this location
            let favBrewery = findBreweryinFavorites(by: view.annotation!)
            // Flip favorite state in the database and in the ui
            favBrewery?.favorite = !(favBrewery?.favorite)!
            let image : UIImage!
            if favBrewery?.favorite == true {
                image = UIImage(named: "small_heart_icon_black_white_line_art.png")?.withRenderingMode(.alwaysOriginal)
            } else {
                image = UIImage(named: "heart_icon.png")?.withRenderingMode(.alwaysOriginal)
            }
            do {
                try coreDataStack?.persistingContext.save()
                DispatchQueue.main.async {
                    (view.leftCalloutAccessoryView as! UIButton).setImage(image!, for: .normal)
                    view.setNeedsDisplay()
                }
            } catch {
                fatalError()
            }
            return
            
        // Goto Webpage Information
        case view.rightCalloutAccessoryView!:
            
            if let str : String = (view.annotation?.subtitle)!,
                let url: URL = URL(string: str) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        default:
            break
        }
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

