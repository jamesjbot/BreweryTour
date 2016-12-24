//
//  MapViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/8/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/**
 This program displays the breweries selected by the user.
 It gets the selection from the mediator and display a red pin for breweries
 and a blue pin for the user's location
 If the user presses on the pin a callout will show allowing the user to
 favorite the brewery, or go the the website for the brewery to check open
 times and current beer selection.
 Clicking on the pin will also zoom in to the pin and give a routing to the
 brewery.
 
 Internals
 The MapViewController only considers what the Mediator currently has selected
 
 When choosing style from CategoryViewController:
 This program will look for beers created with that style ID on the MAIN
 context.
 Then we will grab the breweries by brewer relationship (these also will be pulled from the MAIN context)
 and then map them according to their locations.
 
 When choosing brewery from CategoryViewController:
 The mediator will provide the brewery object, we will map it according to its
 location.
 
 **/


import UIKit
import Foundation
import MapKit
import CoreLocation
import CoreData


class MapViewController : UIViewController {
    
    // MARK: Debugging
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        return
    }
    
    // MARK: Constants
    
    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()
    
    //fileprivate let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext
    
    // MARK: Variables
    
    // Used to hold the locations we are going to display, loaded from a database query
    private var mappableBreweries = [Brewery]()
    // The query that goes against the database to pull in the brewery location information
    // This runs on persistent
    private var frc : NSFetchedResultsController<Brewery> = NSFetchedResultsController()
    private var beerFRC : NSFetchedResultsController<Beer>?
    fileprivate var lastSelectedManagedObject : NSManagedObject?
    // MARK: IBOutlet
    
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
    
    
    // MARK: Functions
    // Debug function please remove
//    func d_showAllBeers() {
//        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
//        request.sortDescriptors = []
//        //request.predicate = []
//        //request.predicate = NSPredicate(format: "styleID = %@", style.id!)
//        var results : [Beer]!
//        coreDataStack?.persistingContext.performAndWait {
//            do {
//                results = try (self.coreDataStack?.persistingContext.fetch(request))! as [Beer]
//                print("MapViewController \(#line) Here are the results\n\(results) ")
//            } catch {
//                self.displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again.")
//                return
//            }
//        }
//    }
    
    
    // Tutoral Function to plot a circular path for the pointer
    private func addCircularPathToPointer() {
        let systemVersion = UIDevice.current.model
        // Circular path
        var point = CGPoint(x: view.frame.midX, y: view.frame.midY)
        var rotationRadius = view.frame.width/4
        if systemVersion == "iPhone" {
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
    
    
    // Find breweries
    fileprivate func findBreweryIDinMainContext(by: MKAnnotation) -> NSManagedObjectID? {
        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        let frc = NSFetchedResultsController(fetchRequest: request,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil, cacheName: nil)
        do {
            try frc.performFetch()
        } catch {
            displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again")
        }
        // Match Brewery name by Title
        for i in frc.fetchedObjects! as [Brewery] {
            if i.name! == by.title! {
                return i.objectID
            }
        }
        return nil
    }
    
    
    
    fileprivate func frcUpdateAppendMapBreweries(newStyle: Bool) {
        // The lastSelectedStyle is the currentSelectedStyle
        // Work thru all the beerResults
        let results = (self.beerFRC?.fetchedObjects)! as [Beer]
        // Now that we have Beers with that style, what breweries are associated with these beers
        // Reset array to hold breweries
        if newStyle {
            self.mappableBreweries = [Brewery]()
        }
        // Mappable breweries will only containg the new breweries
        print("MapView \(#line) were there any beers that matched style\n")
        //print("MapView \(#line) \(results)")
        var newBreweries = [Brewery]()
        //let thisContext = coreDataStack?.mainContext
        for beer in results {
            let breweryRequest = NSFetchRequest<Brewery>(entityName: "Brewery")
            breweryRequest.sortDescriptors = []
            breweryRequest.predicate = NSPredicate(format: "id = %@", beer.breweryID!)
            do {
                let brewery = try (readOnlyContext?.fetch(breweryRequest))! as [Brewery]
                if !self.mappableBreweries.contains(brewery.first!) {
                    self.mappableBreweries.append(brewery.first!)
                    newBreweries.append(brewery.first!)
                }
            } catch {
                self.displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again")
                return
            }
        }
        populateMapWithAnnotations(fromBreweries: newBreweries, removeDisplayedAnnotations: false)
    }
    
    
    // Fetch breweries based on style selected.
    // Get the Brewery entries from the database
    private func initializeFetchAndFetchBreweriesSetIncomingLocations(byStyle : Style){
        print("MapView \(#line) Requesting style: \(byStyle.id!) ")
        let request : NSFetchRequest<Beer> = Beer.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "styleID = %@", byStyle.id!)
        var results : [Beer]!
        // Presave the mainContext maybe that's why I cant see any results.
        //let thisContext = coreDataStack?.mainContext
        beerFRC = NSFetchedResultsController(fetchRequest: request ,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        beerFRC?.delegate = self
        /*
         TODO When you select styles and favorite a brewery, go to favorites breweries and pick a style
         This frc will totally overwrite because it will detect changes in the breweries from favoriting 
         forcing a reload on the mapviewcontroller.
         */
        // This must block because the mapView must be populated before it displays.
//        container?.performBackgroundTask({
//            (context) -> Void in
        readOnlyContext?.performAndWait {
            do {
                try self.beerFRC?.performFetch()
                results = (self.beerFRC?.fetchedObjects)! as [Beer]
                //results = try (thisContext!.fetch(request)) as [Beer]
                print("MapViewController \(#line) The results are zero \(results.count) ")
            } catch {
                self.displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again.")
                return
            }
            //Now that we have Beers with that style, what breweries are associated with these beers
            //Array to hold breweries
            self.mappableBreweries = [Brewery]()
            print("MapView \(#line) were there any beers that matched style\n")
            //print("MapView \(#line) \(results)")
            for beer in results {
                let breweryRequest = NSFetchRequest<Brewery>(entityName: "Brewery")
                breweryRequest.sortDescriptors = []
                breweryRequest.predicate = NSPredicate(format: "id = %@", beer.breweryID!)
                do {
                    let brewery = try (self.readOnlyContext?.fetch(breweryRequest))! as [Brewery]
                    if !self.mappableBreweries.contains(brewery[0]) {
                        self.mappableBreweries.append(brewery[0])
                    }
                } catch {
                    self.displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again")
                    return
                }
            }
            print("MapView \(#line) PerformFetch completed ")
            // The map must be populated when the fetchRequest completes
            self.populateMapWithAnnotations(fromBreweries: self.mappableBreweries, removeDisplayedAnnotations: true)
        }
        //})
//        thisContext?.performAndWait {
//        }
    }
    

    // Puts all the Brewery entries on to the map
    // All breweries in the mappableBreweries array will be added to the screen
    private func populateMapWithAnnotations(fromBreweries: [Brewery],
                                            removeDisplayedAnnotations: Bool){
        print("MapView \(#line) populateMapWithAnnotations called")
        print("MapView \(#line) ploting \(fromBreweries.count) annotations ")
        print("MapView \(#line) Adding these breweries \(fromBreweries)")
        // Remove all the old annotation
        if removeDisplayedAnnotations {
            mapView.removeAnnotations(mapView.annotations)
        }
        // Create new array of annotations
        var annotations = [MKAnnotation]()
        for i in fromBreweries {
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
        
        mapView.addAnnotations(annotations)
        // Add the user's location
        mapView.showsUserLocation = true
        mapView.showsScale = true
        //mapView.showAnnotations(mapView.annotations, animated: true)
        DispatchQueue.main.async {
            self.mapView.setNeedsDisplay()
        }
    }
    
    
    // MARK: View functions
    
    // Ask user for access to their location
    override func viewDidLoad(){
        super.viewDidLoad()
        print("MapView \(#line) ViewDidLoad called ")
        
        // CoreLocation initialization, ask permission to utilize user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }
        
        readOnlyContext?.automaticallyMergesChangesFromParent = true
        
        frc.delegate = self
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Get new selections
        let mapViewData = Mediator.sharedInstance().getMapData()
        
        // Map brewery or breweries by style
        lastSelectedManagedObject = mapViewData
        if mapViewData is Style {
            print("MapView \(#line) this is a style")
            initializeFetchAndFetchBreweriesSetIncomingLocations(byStyle: mapViewData as! Style)
        } else if mapViewData is Brewery {
            // Remove all traces of previous breweries
            print("MapView \(#line) this is a brewery")
            removeRouteOnMap()
            mappableBreweries.removeAll()
            mappableBreweries.append(mapViewData as! Brewery)
            populateMapWithAnnotations( fromBreweries: mappableBreweries, removeDisplayedAnnotations: true)
        } else {
            //TODO remove this return and else
            return
        }
        
        //populateMapWithAnnotations()
    }
    
    
    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)
        
        // Display tutorial view.
        addCircularPathToPointer()
        if UserDefaults.standard.bool(forKey: g_constants.MapViewTutorial) {
            // Do nothing because the tutorial will show automatically.
            tutorialView.isHidden = false
        } else {
            tutorialView.isHidden = true
        }
    }
}


extension MapViewController : MKMapViewDelegate {
    
    // This formats the pins and calloutAccessory views on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        print("MapView \(#line) This many annotations \(mapView.annotations.count)")
        //print("Pin formatting occuring")
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        //if pinView == nil {
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView!.canShowCallout = true
        if (pinView?.annotation?.title)! == mapView.userLocation.title {
            // User's location has doesn't need the other decorations
            pinView!.pinTintColor = UIColor.blue
            return pinView
        } else {
            pinView!.pinTintColor = UIColor.red
        }
        
        // Format annotation callouts here
        pinView?.tintColor = UIColor.red
        pinView?.canShowCallout = true
        
        // Find the brewery in the proper context
        //let thisContext: NSManagedObjectContext = (coreDataStack?.mainContext)!
        let breweryObjectID : NSManagedObjectID! = findBreweryIDinMainContext(by: annotation)!
        //fatalError("This may be the wrong context to look for the brewery in")
        let foundBrewery = readOnlyContext?.object(with: breweryObjectID!) as! Brewery
        
        // Set the favorite icon on pin
        let localButton = UIButton(type: .contactAdd)
        var tempImage : UIImage!
        if foundBrewery.favorite == true {
            tempImage = UIImage(named: "small_heart_icon.png")?.withRenderingMode(.alwaysOriginal)
        } else {
            tempImage = UIImage(named: "small_heart_icon_black_white_line_art.png")?.withRenderingMode(.alwaysOriginal)
        }
        localButton.setImage(tempImage, for: .normal)
        pinView?.leftCalloutAccessoryView = localButton
        // Set the information icon on the right button
        pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        // } else { // Reusing an onscreen pin annotation
        pinView!.annotation = annotation
        // }
        return pinView
    }
    //
    //    func zoomToComfortableLevel() {
    //        let span = MKCoordinateSpanMake(63 , 63)
    //        let region = MKCoordinateRegion(center: centerCoord , span: span)
    //        mapView.setRegion(region, animated: true)
    //    }
    
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
                // Prompt with a warning window
                self.displayAlertWindow(title: "No Routes", msg: "There are no routes available.")            }
        }
        
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
    
    
    // Respond to user taps on the annotation callout
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Did the user favorite or ask for more information on the brewery
        switch control as UIView {
            
        // Favorite or unfavorite a brewery
        case view.leftCalloutAccessoryView!:
            print("MapViewController \(#line) Favorite toggle called ")
            guard (view.annotation?.title)! != "My Locations" else {
                // Do not respond to taps on the user's location callout
                return
            }
            // let favoritingContext = coreDataStack?.mainContext
            // Find the brewery object that belongs to this location
            let tempObjectID = findBreweryIDinMainContext(by: view.annotation!)
            // Fetch object from context
            let favBrewery = readOnlyContext?.object(with: tempObjectID!) as! Brewery
            // Flip favorite state in the database and in the ui
            print("favortie before: \(favBrewery.favorite)")
            favBrewery.favorite = !(favBrewery.favorite)
            print("favortie after: \(favBrewery.favorite)")
            let image : UIImage!
            if favBrewery.favorite == false {
                print("false run")
                image = UIImage(named: "small_heart_icon_black_white_line_art.png")?.withRenderingMode(.alwaysOriginal)
            } else {
                print("true run")
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
                } catch let error {
                    print("Error saving in context \(error)")
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
    
    
    // Render the route line
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
// All code needed for the CLLocationManager to work
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


extension MapViewController : NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("MapViewController \(#line) Detected new changes.")
        // This should only be called when this is a style, because single breweries
        // are immediately displayed
        if lastSelectedManagedObject == Mediator.sharedInstance().getMapData() {
            frcUpdateAppendMapBreweries(newStyle: false)
        } else { // new style replace.
            frcUpdateAppendMapBreweries(newStyle: true)
        }

    }
}


// Tutorial code.
extension MapViewController : DismissableTutorial {

    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}

