//
//  MapViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/8/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
 This view displays the breweries selected by the user.
 It gets the selection from the mediator and display a red pin for breweries
 and a blue pin for the user's location
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
 
 There is a brewery buffer called breweriesToBeProcessed. It gets queued up
 with breweries from the both the initialfetch and also 
 the fetchresultscontrollerdelegate, and processes breweries in batches
 for display on the screen.
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
    let timerDelay = 5
    let maximumClosestBreweries = 100

    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()

    private var debouncedFunction: (()->())? = nil

    // Coredata
    fileprivate let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    fileprivate let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    // MARK: Variables

    fileprivate var beerFRC : NSFetchedResultsController<Beer>? = NSFetchedResultsController<Beer>()
    fileprivate var lastSelectedManagedObject : NSManagedObject?

    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()

    // New breweries with styles variable
    fileprivate var sortedBreweries: [Brewery] = []
    fileprivate var breweriesForDisplay: [Brewery] = [] {
        didSet {
            debouncedFunction!()

            // What is it we are trying to do.
            // I'm trying to make this more responsive.
            // MapView is getting both bogged down by the number of pins to display
            // And by waiting for the processing to finish

            // Requirements that I've made up to help with this
            // 1. Load only the closest breweries
            // 2. Load only maximumClosestbreweries which is 100 right now
            // 3. The wait for loading things is too slow is there a way I can accelerate getting styles in loaded with some beers faster.


            // TODO Your going to have to fix when user presses another styles and the old style is still loading.

            // TODO When you go to create the beers by selcting the above breweries will styles also be populated?

        }
    }


    private func sortBreweriesByDistanceAndDisplay() {
        //print("mapview \(#line) sortBreweriesByDisntanceAndDisplay ")
        // If we have a user location we can sort first
        if self.mapView.userLocation.location != nil {
            sortedBreweries = breweriesForDisplay.sorted(by:
                { (brewery1, brewery2) -> Bool in
                    let location1: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery1.latitude!)!), longitude: CLLocationDegrees(Double(brewery1.longitude!)!))
                    let location2: CLLocation = CLLocation(latitude: CLLocationDegrees(Double(brewery2.latitude!)!), longitude: CLLocationDegrees(Double(brewery2.longitude!)!))
                    return ((self.mapView.userLocation.location?.distance(from: location1))! as Double) < ((self.mapView.userLocation.location?.distance(from: location2))! as Double)
            })
        }

        print("Setting this many points:\(self.breweriesForDisplay.count)")
        var annotations = [MKAnnotation]()

        // Show only the first maximumClosestBreweries points otherwise UI Slows down too much.
        var maxDisplayed: Int = self.breweriesForDisplay.count
        if self.breweriesForDisplay.count > self.maximumClosestBreweries {
            maxDisplayed = self.maximumClosestBreweries
        }

        // Format the first maximumClosestBreweries for display.
        for (number,i) in self.sortedBreweries.enumerated() {

            guard number < maxDisplayed else {
                break
            }

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

        // Draw the annotations on the map
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(annotations)
            // Set the center of the map
            // Calculated form point slope formula where 90degrees with 1 point to .07 degrees with 1000+points
            // Using the below formula to calculate region. where x is number of points y is the dimension size.
            //y = − 0.09002002 x + 90.09002002
            let degrees = -0.99 * Double(self.breweriesForDisplay.count) + 1000000
            self.centerMapOnLocation(location: self.mapView.userLocation.location, radius: degrees)
            //print("------->mapview \(#line) has \(self.mapView.annotations.count) annotations")
            self.activityIndicator.stopAnimating()
            //print("------->mapview \(#line) exiting sortanddisplay ")
        }
    }


    // This function will drop the excessive calls to redisplay the map
    // Borrowed from
    // http://stackoverflow.com/questions/27116684/how-can-i-debounce-a-method-call/33794262#33794262
    private func debounce(delay:Int, queue:DispatchQueue, action: @escaping (()->())) -> ()->() {
        var lastFireTime = DispatchTime.now()
        let dispatchDelay = DispatchTimeInterval.milliseconds(delay)

        return {
            let dispatchTime: DispatchTime = lastFireTime + dispatchDelay
            queue.asyncAfter(deadline: dispatchTime, execute: {
                let when: DispatchTime = lastFireTime + dispatchDelay
                let now = DispatchTime.now()
                if now.rawValue >= when.rawValue {
                    lastFireTime = DispatchTime.now()
                    action()
                }
            })
        }
    }


    func centerMapOnLocation(location: CLLocation?, radius regionRadius: CLLocationDistance) {
        DispatchQueue.main.async {
        guard location != nil else {
            // Center of the U.S.
            let centerCoord = CLLocationCoordinate2D(latitude: 39.5, longitude: -98.35)
            let span = MKCoordinateSpanMake(63 , 63)
            let region = MKCoordinateRegion(center: centerCoord , span: span)
            self.mapView.setRegion(region, animated: true)
            return
        }
        // Set the view region
        //print("Setting Region centered on user location to \(regionRadius) meters")
        let coordinateRegion = MKCoordinateRegionMakeWithDistance((location?.coordinate)!,
                                                                  regionRadius * 2.0, regionRadius * 2.0)
        self.mapView.setRegion(coordinateRegion, animated: true)
        self.mapView.setNeedsDisplay()
        }
    }


    // Timer to make sure allBreweries are processed and put on the map
    private var checkUpTimer: Timer? = nil

    fileprivate var breweriesToBeProcessed: [Brewery] = [Brewery]() {
        didSet {
            activityIndicator.startAnimating()
            // Put the next 50 breweries on the map
            if breweriesToBeProcessed.count >= maxBreweryBuffer {

                populateMapWithAnnotations(fromBreweries: breweriesToBeProcessed, removeDisplayedAnnotations: false)
                breweriesToBeProcessed.removeAll()
                disableTimer()

            } else {
                // less than 50 breweries exist in the queue comeback and map them
                // The last flush out will always be timerDelay seconds after the last insert
                disableTimer()
                checkUpTimer = Timer.scheduledTimer(timeInterval: TimeInterval(timerDelay),
                                                    target: self,
                                                    selector: #selector(timerProcessUnfullQueue),
                                                    userInfo: nil,
                                                    repeats: true)
            }
        }
    }


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
    
    
    // MARK: Functions

    // Turns off the breweriesToBeProcessed timer
    private func disableTimer() {
        if checkUpTimer != nil {
            checkUpTimer?.invalidate()
        }
    }

    // Process the last unfull set on the breweriesToBeProcessed queue.
    @objc private func timerProcessUnfullQueue() {
        if breweriesToBeProcessed.count > 0 {
            populateMapWithAnnotations(fromBreweries: breweriesToBeProcessed, removeDisplayedAnnotations: false)
            breweriesToBeProcessed.removeAll()
            disableTimer()
            activityIndicator.stopAnimating()
        }
    }


    // Find brewery by name in annotation
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


    private func newInitialFetchBreweries(byStyle: Style) {
        // Fetch all the Breweries with style
        let request : NSFetchRequest<Style> = Style.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", byStyle.id!)
        // A static view of current breweries with styles
        styleFRC = NSFetchedResultsController(fetchRequest: request ,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        do {
            try styleFRC.performFetch()
            //print("Found style \(styleFRC.fetchedObjects?.first?.brewerywithstyle)")
            breweriesForDisplay = styleFRC.fetchedObjects?.first?.brewerywithstyle?.allObjects as! [Brewery]
        } catch {
            
        }
        styleFRC.delegate = self
    }


    fileprivate func fetchAndDisplay() {
        do {
            try styleFRC.performFetch()
            //print("Found style \(styleFRC.fetchedObjects?.first?.brewerywithstyle)")
            breweriesForDisplay = styleFRC.fetchedObjects?.first?.brewerywithstyle?.allObjects as! [Brewery]
        } catch {
        }
    }


    /*
     This function is only called on viewWillAppear
     It fetches breweries based on style selected.
     Get the Brewery entries from the database
     */
    private func initializeFetchAndFetchBreweriesSetIncomingLocations(byStyle : Style){
        print("MapView \(#line) initializeFetchAndFetchBreweries called Requesting style: \(byStyle.id!) ")
        // Fetch all the beers with style currently available
        // Go thru each beer if the brewery is on the map skip it
        // If not put the beer's brewery in breweriesToBeProcessed.

        // Fetch all the beers with style
        let request : NSFetchRequest<Beer> = Beer.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "styleID = %@", byStyle.id!)
        // A static view of current breweries with styles
        var results : [Beer]!
        beerFRC = NSFetchedResultsController(fetchRequest: request ,
                                             managedObjectContext: readOnlyContext!,
                                             sectionNameKeyPath: nil,
                                             cacheName: nil)
        // Sign up for updates
        beerFRC?.delegate = self

        // Prime the fetched results controller
        do {
            _ = try beerFRC?.performFetch()
            results = (beerFRC?.fetchedObjects!)! as [Beer]
        } catch {
            self.displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again.")
            return
        }
        // Now that we have Beers with that style, what breweries are associated
        // with these beers
        var uniqueBreweries = [Brewery]() // Array to hold breweries

        // Remove duplicate breweries
        for beer in results {
            if beer.brewer != nil {
                // Only unique breweries are processed
                if !uniqueBreweries.contains(beer.brewer!) {
                    uniqueBreweries.append(beer.brewer!)
                    // Hand breweries off to be processed.
                    breweriesToBeProcessed.append(beer.brewer!)
                }
            }
        }
        // The map must be populated when the fetchRequest completes
        // TODO Adding breweries to tobeprocessed does the same thing as this line
        // consider deleting it after testing.
        //populateMapWithAnnotations(fromBreweries: mappableBreweries, removeDisplayedAnnotations: true)
        print("MapView \(#line) completed adding unique to processed \(uniqueBreweries.count) ")

    }


    private func removeDuplicatesFromNewAnnotations(orignal: [MKAnnotation],
                                                    new: [Brewery]) {

    }

    // Puts all the Brewery entries on to the map
    // All breweries in the breweriesToBeProcessed array will be added to the screen
    fileprivate func populateMapWithAnnotations(fromBreweries: [Brewery],
                                                removeDisplayedAnnotations: Bool){

        // Remove all the old annotations or remove new duplicates
        var duplicateFree = fromBreweries
        if removeDisplayedAnnotations {
            // TODO Removed for testing new additions.
            //mapView.removeAnnotations(mapView.annotations)

        } else { // Remove duplicates
            var duplicateIndices = [Int]()
            new: for (i, element) in duplicateFree.enumerated() {
                for j in mapView.annotations {
                    if element.latitude == j.coordinate.latitude.description &&
                        element.longitude == j.coordinate.longitude.description {
                        duplicateIndices.append(i)
                        continue new
                    }
                }
            }
            duplicateIndices.sort()
            duplicateIndices.reverse()
            for i in duplicateIndices {
                duplicateFree.remove(at: i)
            }

        }
        // Create new array of annotations
        var annotations = [MKAnnotation]()
        for i in duplicateFree {
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
        // Map the annotations
        addAnnotationsToMapAndSetNeedsDisplay(annotations: annotations)
    }

    private func addAnnotationsToMapAndSetNeedsDisplay(annotations: [MKAnnotation]) {
        mapView.addAnnotations(annotations)
        let dt = DispatchTime(uptimeNanoseconds: 1000)
        DispatchQueue.main.asyncAfter(deadline: dt) {
            self.mapView.setNeedsDisplay()
        }
    }


    // MARK: View functions

    // Ask user for access to their location
    override func viewDidLoad(){
        super.viewDidLoad()
        debouncedFunction = debounce(delay: 3000, queue: DispatchQueue.main, action: {
                self.sortBreweriesByDistanceAndDisplay()
        })

        assert(beerFRC != nil)
        // Register with mediator for contextUpdates
        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)

        // Register for map updates to style
        //(Mediator.sharedInstance() as ObserverMapChanges).registerMapObservers(m: self)

        DispatchQueue.main.async{
            self.mapView.showsUserLocation = true
            self.activityIndicator.startAnimating()
        }
        // CoreLocation initialization, ask permission to utilize user location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
            locationManager.requestLocation()
        }
        // Allow other contexts to push data to ours.
        readOnlyContext?.automaticallyMergesChangesFromParent = true

        // Move the map to user location.
//        print("InViewdid load \(mapView.userLocation.coordinate)")
//        mapView.setCenter(mapView.userLocation.coordinate, animated: true)
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "Go To Website"
        mapView.showsUserLocation = true
        mapView.showsScale = true
        mapView.showsCompass = true

        guard lastSelectedManagedObject != Mediator.sharedInstance().getPassedItem() else {
            // No need to update the viewcontroller if the data has not changed
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
            return
        }

        // Get new selection
        let mapViewData = Mediator.sharedInstance().getPassedItem()

        // Zoom to users location first if we have it.
        if mapView.userLocation != nil {
            mapView.setCenter(mapView.userLocation.coordinate, animated: false)

        }

        // Decision making to display Breweries Style or Brewery
        if mapViewData is Style {

            newInitialFetchBreweries(byStyle: mapViewData as! Style)
            //initializeFetchAndFetchBreweriesSetIncomingLocations(
                //byStyle: mapViewData as! Style)
            activityIndicator.stopAnimating()

        } else if mapViewData is Brewery {

            // Remove all traces of previous breweries
            removeRouteOnMap()
            breweriesToBeProcessed.removeAll()
            populateMapWithAnnotations( fromBreweries: [mapViewData as! Brewery], removeDisplayedAnnotations: true)
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
        } else { // No Selection what so ever
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
            }
        }

        // Capture last selection, so we can compare when an update is requested
        lastSelectedManagedObject = mapViewData

    }


    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)
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


// MARK: - MapViewController: UpdateManagedObjectContext

extension MapViewController: UpdateManagedObjectContext {
    internal func contextsRefreshAllObjects() {
        //beerFRC?.managedObjectContext.refreshAllObjects()

        styleFRC.managedObjectContext.refreshAllObjects()
        // We must performFetch after refreshing context, otherwise we will retain
        // Old information is retained.
        do {
            //try beerFRC?.performFetch()

            try styleFRC.performFetch()
        } catch {

        }
    }
}


// MARK: - MapViewController : MKMapViewDelegate

extension MapViewController : MKMapViewDelegate {
    
    // This formats the pins and calloutAccessory views on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }

        pinView!.canShowCallout = true

        // If incoming annotation is user location.
        if mapView.userLocation.coordinate.latitude == annotation.coordinate.latitude ,
            mapView.userLocation.coordinate.longitude == annotation.coordinate.longitude {
            // User's location has doesn't need the other decorations
            pinView!.pinTintColor = UIColor.black
            return pinView

        } else { // breweries
            pinView?.pinTintColor = UIColor.orange
        }
        
        // Format annotation callouts here
        pinView?.tintColor = UIColor.red

        // Find the brewery in the proper context
        let foundBrewery = readOnlyContext?.object(with: (convertAnnotationToObjectID(by: annotation))!) as! Brewery

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
        pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        pinView?.annotation = annotation
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
        // UIControl is subclass of UIView
        // Testing if UIControl is one of the MKAnnotationView's subviews

        // Favorite or unfavorite a brewery
        case view.leftCalloutAccessoryView!:
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


// MARK: - MapViewController: CLLocationManagerDelegate
/*
 Places the placemark for User's current location
 All code needed for the CLLocationManager to work
*/
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

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("\n------->MapView \(#line) Controller will change content")
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        //print("------->MapView \(#line) controller did change anobject called.")
        switch (type){
        case .insert:
            //print("------->MapView \(#line) insert ")
            break
        case .delete:
            //print("------->mapview \(#line) delete ")
            break
        case .move:
            break
        case .update:
            //print("------->mapview \(#line) update ")
            break
        }
    }
    internal func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        //print("------->Run \(styleUpdateCounter) mapview \(#line) finishedchanging\n")
        breweriesForDisplay = (controller.fetchedObjects?.first as! Style).brewerywithstyle?.allObjects as! [Brewery]
    }

//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        guard let brewer = (anObject as? Beer)?.brewer else {
//            return
//        }
//        // Only newly inserted breweries will be processed
//        if type == NSFetchedResultsChangeType.insert  {
//            breweriesToBeProcessed.append(brewer)
//        }
//
//    }
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

// MARK: MapViewController: MapUpdateable

extension MapViewController: MapUpdateable {
    func updateMap() {
        fetchAndDisplay()
    }
}




