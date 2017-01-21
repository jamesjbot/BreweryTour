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
 The MapViewController takes what the Mediator currently has selected
 
 Then viewWillAppear chooses the strategy based on the selected item
 MapStrategy the super class maps multiple breweries on the map.
 It does this by sorting and finally send the annotation back to the update
 map function.
 For brewery we just immediately display the brewery's location by sending it as 
 a single brewery to it's superclass MapStrategy
 For style we 

 When choosing brewery from CategoryViewController:
 The mediator will provide the brewery object, we will map breweries according 
 their location.
 
 The appropriate strategy to convert to annotations will be chosen by style or 
 brewery type that enter
 
 Then when it finishes it will send the annotation back
 */


import UIKit
import Foundation
import MapKit
import CoreLocation
import CoreData

class MapViewController : UIViewController {
    
    // MARK: Constants
    let reuseId = "pin"
    let circularAnimationDuration = 5
    let radiusDivisor = 4
    let iphoneFactor = 2
    let centerLocation = CLLocation(latitude: 39.5, longitude: -98.35)

    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()

    // Coredata
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    // MARK: Variables

    fileprivate var routedAnnotation: MKAnnotationView?

    fileprivate var floatingAnnotation: MKAnnotation!

    fileprivate var targetLocation: CLLocation?

    fileprivate var activeMappingStrategy: MapStrategy? = nil

    fileprivate var lastSelectedManagedObject : NSManagedObject?

    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()

    // New breweries with styles variable
    fileprivate var sortedBreweries: [Brewery] = []
    @IBOutlet weak var currentLocation: UIButton!
    fileprivate var breweriesForDisplay: [Brewery] = [] 

    // MARK: IBOutlet

    @IBOutlet weak var longPressRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var numberOfPoints: UILabel!
    @IBOutlet weak var slider: UISlider!
    

    // MARK: IBAction

    @IBAction func currentLocationTapped(_ sender: UIButton) {
        clearPointFromTargetLocation()
    }


    @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {
            // Remove redundant calls to long press
        mapView.resignFirstResponder()

        // Always set a pin down when user presses down
        // When the pin state is changed delete old pin and replace with new pin
        // When user release drop the pin and save it to the database
        print(sender.state.rawValue)
        print("Long press detected")
        switch sender.state {
        case UIGestureRecognizerState.began:

            // Remove old annotation
            if floatingAnnotation != nil {
                mapView.removeAnnotation(floatingAnnotation)
            }

            // Set floating annotation
            let coordinateOnMap = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinateOnMap
            mapView.addAnnotation(annotation)
            floatingAnnotation = annotation

        case UIGestureRecognizerState.changed:
            // Move floating annotation
            mapView.removeAnnotation(floatingAnnotation)
            let coordinateOnMap = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinateOnMap
            mapView.addAnnotation(annotation)
            floatingAnnotation = annotation

        case UIGestureRecognizerState.ended:
            // Make new pointer targetlocation
            makePointTargetLocation()

        case UIGestureRecognizerState.cancelled:
            break

        case UIGestureRecognizerState.failed:
            break

        case UIGestureRecognizerState.possible:
            break
        }
    }


    @IBAction func sliderTouchUpInside(_ sender: UISlider, forEvent event: UIEvent) {
        guard mapView.userLocation.coordinate.latitude != 0,
            mapView.userLocation.coordinate.longitude != 0 else {
                return
        }
        let intValue: Int = Int(sender.value)
        numberOfPoints.text = String(intValue)

        // Save slider value for the future
        Mediator.sharedInstance().setLastSliderValue(intValue)

        // Replotting
        let mapViewData = Mediator.sharedInstance().getPassedItem()
        guard mapViewData is Style else {
            return
        }

        (activeMappingStrategy as! StyleMapStrategy).endSearch()
        activeMappingStrategy = StyleMapStrategy(s: mapViewData as! Style,
                                                 view: self,
                                                 location: targetLocation!,
                                                 maxPoints: Int(slider.value))

    }


    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        let intValue: Int = Int(sender.value)
        numberOfPoints.text = String(intValue)
    }


    @IBAction func dismissTutorial(_ sender: UIButton) {
        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.MapViewTutorial)
        UserDefaults.standard.synchronize()
    }
    
    
    // MARK: - Functions

    private func makePointTargetLocation() {
        let location = CLLocation(latitude: floatingAnnotation.coordinate.latitude, longitude: floatingAnnotation.coordinate.longitude)
        targetLocation = location
        displayNewStrategyWithNewPoint()
    }


    @objc private func clearPointFromTargetLocation() {
        guard floatingAnnotation != nil else {
            return
        }
        mapView.removeAnnotation(floatingAnnotation)
        floatingAnnotation = nil
        // Reset back to user true location
        targetLocation = nil
        displayNewStrategyWithNewPoint()
    }


    private func setTargetLocationWhenTargetLocationIsNil() {
        // Zoom to users location first if we have it.
        // When we first join the mapview and the userlocation has not been set.
        // It will default to 0,0, so we center the location in the US

        // TODO When centerlocation comes in
        // When userlocation comes in
        // When arbitratylocation comes in


        // Only do these when target location is nil or this 
        // is the temporary centerLocation
        
        guard targetLocation == nil || targetLocation == centerLocation else {
            return
        }

        let uninitialzedLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        if mapView.userLocation.coordinate.latitude == uninitialzedLocation.latitude &&
            mapView.userLocation.coordinate.longitude == uninitialzedLocation.longitude {
            targetLocation = centerLocation
            print("Using our center location because user location has not been populated")
        } else {
            //mapView.setCenter(mapView.userLocation.coordinate, animated: false)
            targetLocation = mapView.userLocation.location
            print("User location is \(targetLocation)")
        }
    }


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


    private func compareCoordinates(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
        if a.latitude == b.latitude && a.longitude == b.longitude {
            return true
        }
        return false
    }


    func isAnnotation(inArray: [MKAnnotation]) -> Bool {
        if let routedAnnotation = routedAnnotation {
            for i in inArray {
                print(inArray)
                print(routedAnnotation)
                if compareCoordinates(a: i.coordinate, b: (routedAnnotation.annotation?.coordinate)!) {
                    return true
                }
            }
        }
        return false
    }


    // Draw the annotations on the map
    internal func updateMap(b: [MKAnnotation]) {

        if !isAnnotation(inArray: b) {
            mapView.removeOverlays(mapView.overlays)
        }

        // If the annotation display are the same do nothing
        var copy = mapView.annotations
        // remove floatingannotation
        if !copy.isEmpty {
            copy.removeLast()
        }
        let theseArraysAreSame = arraysAreDifferent(a: copy, b: b)
        print(copy)
        print(b)
        print("These arrays are the different \(theseArraysAreSame)")
        guard arraysAreDifferent(a: copy, b: b) else {
            print("STOPPING UPDATER--------------------------------------------")
            return
        }

        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(b)
            // Add back out floating annotation we deleted.
            if let floatingAnnotation = self.floatingAnnotation {
                self.mapView.addAnnotation(floatingAnnotation)
            }
        }
    }


    private func arraysAreDifferent(a: [MKAnnotation], b: [MKAnnotation]) -> Bool {
        guard a.count == b.count else {
            return true
        }

        // They are either both zero or both not zero
        guard a.count != 0 && b.count != 0 else {
            return false
        }

        for i in a {
            for j in b {
                print("i:\(i.coordinate) j:\(j.coordinate)")
                if i.coordinate.latitude != j.coordinate.latitude ||
                    i.coordinate.longitude != j.coordinate.longitude {
                    return true
                }
            }
        }
        return false
    }


    private func createCurrentLocationButton() {
        let userLocationButton = UIBarButtonItem(title: "Current location", style: .plain, target: self, action: #selector(clearPointFromTargetLocation))
        self.navigationItem.setRightBarButtonItems([userLocationButton], animated: true)
    }


    private func initCoreLoction() {
        // CoreLocation initialization, ask permission to utilize user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }
    }

    // MARK: - View Life Cycle functions

    // Ask user for access to their location
    override func viewDidLoad(){
        super.viewDidLoad()

        DispatchQueue.main.async{
            self.mapView.showsUserLocation = true
            self.mapView.showsScale = true
            self.mapView.showsCompass = true
        }

        initCoreLoction()

        registerAsBusyObserverWithMediator()

        mapView.addGestureRecognizer(longPressRecognizer)

        createCurrentLocationButton()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        print("\(mapView.userLocation.location)")

        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }

        // Set the function of this screen
        tabBarController?.title = "Go To Website"

        // Set slider value and text
        slider.value = Float(Mediator.sharedInstance().lastSliderValue())
        numberOfPoints.text = "\(Int(slider.value))"

        // TODO Delete?When we first start up and nothing has been selected and we click map
        // It will come here there is no last selected and mediator has nothing
        // so the map view will show the last view ( default view) nothing
        // TODO Delete?       guard lastSelectedManagedObject != mapViewData else {
        //            // No need to update the viewcontroller if the data has not changed
        //            return Doesn't work because viewDidLoad is caleld again?
        //        }
        displayNewStrategyWithNewPoint()
    }


    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)

        tutorialInitialization()
    }


    private func tutorialInitialization() {
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


    fileprivate func displayNewStrategyWithNewPoint() {

        // Get new selection
        let mapViewData = Mediator.sharedInstance().getPassedItem()
        // If there is nothing no changes need to be made to the map
        guard mapViewData != nil else {
            return
        }

        // TODO When we first start up and nothing has been selected and we click map
        // It will come here there is no last selected and mediator has nothing
        // so the map view will show the last view ( default view) nothing
//        guard lastSelectedManagedObject != mapViewData else {
//            // No need to update the viewcontroller if the data has not changed
//            return Doesn't work because viewDidLoad is caleld again?
//        }

        setTargetLocationWhenTargetLocationIsNil()

        decideOnMappingStrategyAndInvoke(mapViewData: mapViewData!)

        // Capture last selection, so we can compare when an update is requested
        lastSelectedManagedObject = mapViewData

        activateIndicatorIfSystemBusy()

    }

    private func decideOnMappingStrategyAndInvoke(mapViewData: NSManagedObject) {
        // Decision making to display Breweries Style or Brewery
        if mapViewData is Style {

            activeMappingStrategy = StyleMapStrategy(s: mapViewData as! Style,
                                                     view: self,
                                                     location: targetLocation!,
                                                     maxPoints: Int(slider.value))

        } else if mapViewData is Brewery {

            activeMappingStrategy = BreweryMapStrategy(b: mapViewData as! Brewery,
                                                       view: self,
                                                       location: targetLocation!)
            
        }
    }

    private func activateIndicatorIfSystemBusy() {
        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
    }

}



// MARK: - MKMapViewDelegate

extension MapViewController : MKMapViewDelegate {

    //Find brewery objectid by using name in annotation
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


    // This formats the pins and calloutAccessory views on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MyPinAnnotationView
        if pinView == nil {
            pinView = MyPinAnnotationView(annot: annotation, reuse: reuseId)
        }

        pinView!.canShowCallout = true

        if annotation === floatingAnnotation {
            pinView!.pinTintColor = UIColor.magenta
            return pinView
        }

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

        // Save the routed annotation
        routedAnnotation = view

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
                context.performAndWait {
                    do {
                        try context.save()
                    } catch _ {
                        self.displayAlertWindow(title: "Error", msg: "Sorry there was an error toggling your favorite brewery, \nplease try again")
                    }
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


// MARK: - CLLocationManagerDelegate
// TODO initial placement is still going toward the center of the map
// Places the placemark for User's current location
 extension MapViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        return
    }


    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("DID update user location \(userLocation)")
        displayNewStrategyWithNewPoint()
        return
    }


    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }
    
}


// MARK: - NSFetchedResultsControllerDelegate

extension MapViewController : NSFetchedResultsControllerDelegate {
    // Used for when style is updated with new breweries
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        breweriesForDisplay = (controller.fetchedObjects?.first as! Style).brewerywithstyle?.allObjects as! [Brewery]
    }
}


// MARK: - DismissableTutorial
// Tutorial code.

extension MapViewController : DismissableTutorial {

    // Tutoral Function to plot a circular path for the pointer
    fileprivate func addCircularPathToPointer() {
        // Circular path
        var point = CGPoint(x: view.frame.midX, y: view.frame.midY)
        var rotationRadius = view.frame.width/CGFloat(radiusDivisor)

        if UIDevice.current.model == "iPhone" {
            point = CGPoint(x: view.frame.midX, y: view.frame.midY * 0.5)
            rotationRadius = view.frame.width/CGFloat(radiusDivisor*iphoneFactor)
        }

        let circlePath = UIBezierPath(arcCenter: point,
                                      radius: rotationRadius,
                                      startAngle: 0,
                                      endAngle:CGFloat(M_PI)*2,
                                      clockwise: true)
        let circularAnimation = CAKeyframeAnimation(keyPath: "position")
        circularAnimation.duration = CFTimeInterval(circularAnimationDuration)
        circularAnimation.repeatCount = MAXFLOAT
        circularAnimation.path = circlePath.cgPath
        pointer.layer.add(circularAnimation, forKey: nil)
        pointer.isHidden = false
    }


    internal func enableTutorial() {
        tutorialView.isHidden = false
    }
}


// MARK: - BusyObserver

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




