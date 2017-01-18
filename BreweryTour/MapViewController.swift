//
//  MapViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/8/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This view displays the breweries selected by the user.
 It gets the selection from the mediator and display an orange pin for breweries
 and a black pin for the user's location
 If the user presses on the pin a callout will show allowing the user to
 favorite the brewery, or go the the website for the brewery to check open
 times and current beer selection.
 Clicking on the pin will also zoom in to the pin and give a routing to the
 brewery.
 
 Internals
 The MapViewController only considers what the Mediator currently has selected
 
 When choosing brewery from CategoryViewController:
 The mediator will provide the brewery object, we will map breweries according 
 their location.
 
 The appropriate strategy to convert to annotations will be chosen by style or 
 brewery type that enter
 */


import UIKit
import Foundation
import MapKit
import CoreLocation
import CoreData

class MapViewController : UIViewController {
    
    // MARK: Constants
    let reuseId = "pin"
    let maxBreweryBuffer = 50
    let bounceDelay = 5000 // 5 seconds
    let maximumClosestBreweries = 100
    let centerLocation = CLLocation(latitude: 39.5, longitude: -98.35)

    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()

    // Coredata
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    // MARK: Variables

    fileprivate var activeMappingStrategy: MapStrategy? = nil

    fileprivate var lastSelectedManagedObject : NSManagedObject?

    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()

    // New breweries with styles variable
    fileprivate var sortedBreweries: [Brewery] = []
    fileprivate var breweriesForDisplay: [Brewery] = [] 

    // MARK: IBOutlet

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    

    // MARK: IBAction
    
    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.MapViewTutorial)
        UserDefaults.standard.synchronize()
    }
    
    
    // MARK: - Functions

    func centerMapOnLocation(location: CLLocation?, radius regionRadius: CLLocationDistance?, centerUS: Bool) {
        DispatchQueue.main.async {
            guard ( location != nil && !centerUS )  else {
                // Center of the U.S.
                let span = MKCoordinateSpanMake(63 , 63)
                let region = MKCoordinateRegion(center: self.centerLocation.coordinate , span: span)
                self.mapView.setRegion(region, animated: true)
                self.mapView.setNeedsDisplay()
                return
            }
            // Set the view region
            let coordinateRegion = MKCoordinateRegionMakeWithDistance((location?.coordinate)!,
                                                                      regionRadius! * 2.0, regionRadius! * 2.0)
            self.mapView.setRegion(coordinateRegion, animated: true)
            self.mapView.setNeedsDisplay()
        }
    }


    // Find brewery objectid by using name in annotation
    fileprivate func convertAnnotationToObjectID(by: MKAnnotation) -> NSManagedObjectID? {
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "name = %@", by.title!! )
        do {
            let breweries = try readOnlyContext?.fetch(request)
            if let brewery = breweries?.first {
                return brewery.objectID
            }
        } catch {
            displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again")
        }
        return nil
    }


    internal func updateMap(b: [MKAnnotation]) {
        // Draw the annotations on the map
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(b)
        }
    }


    // MARK: - View functions

    // Ask user for access to their location
    override func viewDidLoad(){
        super.viewDidLoad()

        DispatchQueue.main.async{
            self.mapView.showsUserLocation = true
            self.mapView.showsScale = true
            self.mapView.showsCompass = true
        }

        // CoreLocation initialization, ask permission to utilize user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }

        registerAsBusyObserverWithMediator()

    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }

        // Set the function of this screen
        tabBarController?.title = "Go To Website"

        // Get new selection
        let mapViewData = Mediator.sharedInstance().getPassedItem()

        guard mapViewData != nil else {
            return 
        }

        // When we first start up and nothing has been selected and we click map
        // It will come here there is no last selected and mediator has nothing 
        // so the map view will show the last view ( default view) nothing
        guard lastSelectedManagedObject != mapViewData else {
            // No need to update the viewcontroller if the data has not changed
            return
        }


        // Zoom to users location first if we have it.
        // When we first join the mapview and the userlocation has not been set.
        // It will default to 0,0, so we center the location in the US
        let uninitialzedLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        if mapView.userLocation.coordinate.latitude == uninitialzedLocation.latitude &&
            mapView.userLocation.coordinate.longitude == uninitialzedLocation.longitude {
            centerMapOnLocation(location: nil, radius: nil, centerUS: true)
        } else {
            mapView.setCenter(mapView.userLocation.coordinate, animated: false)
        }

        // Which location will we use as distance reference.
        var targetLocation: CLLocation?
        if mapView.userLocation.coordinate.latitude == uninitialzedLocation.latitude &&
            mapView.userLocation.coordinate.longitude == uninitialzedLocation.longitude {
            targetLocation = centerLocation
        } else {
            targetLocation = mapView.userLocation.location
        }

        // Decision making to display Breweries Style or Brewery
        if mapViewData is Style {

            activeMappingStrategy = StyleMapStrategy(s: mapViewData as! Style,
                                                     view: self,
                                                     location: targetLocation!)

        } else if mapViewData is Brewery {

            activeMappingStrategy = BreweryMapStrategy(b: mapViewData as! Brewery,
                                                       view: self,
                                                       location: targetLocation!)

        } else { // No Selection what so ever
            fatalError()
        }

        // Capture last selection, so we can compare when an update is requested
        lastSelectedManagedObject = mapViewData

        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
    }


    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)

        // Tutorial layers
        // Adds a circular path to tutorial pointer
        addCircularPathToPointer()

        // Display tutorial view.
        if UserDefaults.standard.bool(forKey: g_constants.MapViewTutorial) {
            // Do nothing because the tutorial will show automatically.
            tutorialView.isHidden = false

        } else {
            tutorialView.isHidden = true
        }
    }
}


// MARK: - MapViewController : MKMapViewDelegate

extension MapViewController : MKMapViewDelegate {
    
    // This formats the pins and calloutAccessory views on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MyPinAnnotationView
        if pinView == nil {
            pinView = MyPinAnnotationView(annot: annotation, reuse: reuseId)
        }

        pinView!.canShowCallout = true

        // If incoming annotation is user location.
        if mapView.userLocation.coordinate.latitude == annotation.coordinate.latitude ,
            mapView.userLocation.coordinate.longitude == annotation.coordinate.longitude {
            // User's location doesn't need the other decorations
            pinView!.pinTintColor = UIColor.black
            return pinView

        } else { // breweries
            pinView?.pinTintColor = UIColor.orange
        }

        // Find the brewery in the proper context,
        // If not then this is the user location.
        // No formating needed on user location.
        guard let objectID = convertAnnotationToObjectID(by: annotation),
            let foundBrewery = readOnlyContext?.object(with: objectID) as? Brewery else {
                return pinView
        }

        // Set the found brewery to the pin
        return pinView?.setBrewery(foundBrewery)
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
        request.transportType = .automobile // Plottable directions for car only
        let directions = MKDirections(request: request)
        directions.calculate(){
            (response , error ) -> Void in

            if let routeResponse = response?.routes {

                self.removeRouteOnMap()
                // Need to sort to just the fastest travel time one
                let quickestRoute : MKRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})[0]
                self.displayRouteOnMap(route: quickestRoute)

            } else { // No car routes found, Prompt with a warning window

                self.displayAlertWindow(title: "No Routes", msg: "There are no routes available.")
            }
        }
    }


    // Respond to user taps on the annotation callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Did the user favorite or ask for more information on the brewery
        switch control as UIView {
        // UIControl is subclass of UIView
        // Testing if UIControl is one of the MKAnnotationView's subviews

        case view.leftCalloutAccessoryView!:// Favorite or unfavorite a brewery

            guard (view.annotation?.title)! != "My Locations" else {
                // Do not respond to taps on the user's location callout
                return
            }

            // Find the brewery object that belongs to this location
            let tempObjectID = convertAnnotationToObjectID(by: view.annotation!)

            // Fetch object from context
            let favBrewery = readOnlyContext?.object(with: tempObjectID!) as! Brewery

            // Flip favorite state in the database and in the ui
            favBrewery.favorite = !(favBrewery.favorite)
            let image : UIImage!
            if favBrewery.favorite == false {

                image = UIImage(named: "small_heart_icon_black_white_line_art.png")?.withRenderingMode(.alwaysOriginal)

            } else {

                image = UIImage(named: "heart_icon.png")?.withRenderingMode(.alwaysOriginal)
            }

            // Update favorite icon in accessory callout
            DispatchQueue.main.async {
                (view.leftCalloutAccessoryView as! UIButton).setImage(image!, for: .normal)
                view.setNeedsDisplay()
            }

            // Save favorite status and update map
            container?.performBackgroundTask(){
                (context) -> Void in
                (context.object(with: tempObjectID!) as! Brewery).favorite = favBrewery.favorite
                do {
                    try context.save()
                } catch _ {
                    self.displayAlertWindow(title: "Error", msg: "Sorry there was an error toggling your favorite brewery, \nplease try again")
                }
            }
            break
            
        // Goto Webpage Information
        case view.rightCalloutAccessoryView!:
            
            if let str : String = (view.annotation?.subtitle)!,
                let url: URL = URL(string: str) {
                if UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
            break
            
        default:
            break
        }
    }

}


// MARK: - MapViewController Routes

extension MapViewController {

    // Render the route line
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = UIColor.green.withAlphaComponent(0.5)
            polylineRenderer.lineWidth = 3
        }
        return polylineRenderer
    }

    // Removes all routes from map
    func removeRouteOnMap(){
        mapView.removeOverlays(mapView.overlays)
    }


    // Display the route on map
    func displayRouteOnMap(route: MKRoute){
        mapView.add(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(120.0,120.0,120.0,120.0), animated: true)
    }

    // Utility function to convert annotation coordinates to MKMapitems
    func convertToMKMapItemThis(_ view: MKAnnotationView) -> MKMapItem {
        return MKMapItem(placemark: MKPlacemark(coordinate: (view.annotation?.coordinate)!))
    }
}


// MARK: - MapViewController: CLLocationManagerDelegate

// Places the placemark for User's current location
 extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        CLGeocoder().reverseGeocodeLocation(locations.last!){
            (placemarks, error) -> Void in
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }
    
}


// MARK: - MapViewController : NSFetchedResultsControllerDelegate

extension MapViewController : NSFetchedResultsControllerDelegate {
    // Used for when style is updated with new breweries
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        breweriesForDisplay = (controller.fetchedObjects?.first as! Style).brewerywithstyle?.allObjects as! [Brewery]
    }
}

// MARK: - MapViewController : DismissableTutorial
// Tutorial code.
extension MapViewController : DismissableTutorial {

    // Tutoral Function to plot a circular path for the pointer
    fileprivate func addCircularPathToPointer() {
        // Circular path
        var point = CGPoint(x: view.frame.midX, y: view.frame.midY)
        var rotationRadius = view.frame.width/4

        if UIDevice.current.model == "iPhone" {
            point = CGPoint(x: view.frame.midX, y: view.frame.midY*0.5)
            rotationRadius = view.frame.width/8
        }

        let circlePath = UIBezierPath(arcCenter: point,
                                      radius: rotationRadius,
                                      startAngle: 0,
                                      endAngle:CGFloat(M_PI)*2,
                                      clockwise: true)
        let circularAnimation = CAKeyframeAnimation(keyPath: "position")
        circularAnimation.duration = 5
        circularAnimation.repeatCount = MAXFLOAT
        circularAnimation.path = circlePath.cgPath
        pointer.layer.add(circularAnimation, forKey: nil)
        pointer.isHidden = false
    }


    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}

extension MapViewController: BusyObserver {

    func startAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.startAnimating()
        }
    }

    func stopAnimating() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
        }
    }


    func registerAsBusyObserverWithMediator() {
        Mediator.sharedInstance().registerForBusyIndicator(observer: self)
    }
    
}





