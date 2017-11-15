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
 The MapViewController takes what the Mediator currently has selected,
 then viewWillAppear chooses the strategy based on the selected item.

 MapStrategy is the super class, maps multiple breweries on the map.
 It does this by sorting and finally sending the annotation back to the update
 map function.

 For brewery we just immediately display the brewery's location by sending it as
 a single brewery to it's superclass MapStrategy, which sends it back to our
 updateMapFunction

 For style we create a StyleMapStrategy, that enters its own loop to process
 breweries currently in the database and new ones that are being downloaded.
 It stays alive till it process all its beers or a new style strategy has
 replaced it in the Mediator's currently running StyleStrategy

 The use can now select to show local beers by going into the + menu
 and selecting show local beers.
 Moving the pointer still works and it will query beers for the state that point
 is in.
 */


import UIKit
import Foundation
import MapKit
import CoreLocation
import CoreData
import SwiftyBeaver

/// Adapter class to sort/filter annotations
fileprivate class AnnotationAdapter: NSObject {

    var annotation: MKAnnotation?
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    override init() {
        super.init()
    }

    init(_ mka: MKAnnotation) {
        super.init()
        annotation = mka
        coordinate = mka.coordinate
        title = mka.title!
        subtitle = mka.subtitle!
    }

    override func isEqual(_ object: Any?) -> Bool {
        if object is AnnotationAdapter {
            return title == (object as! AnnotationAdapter).title
        }
        return false
    }

    override var hashValue: Int {
        if let hash = title?.hashValue {
            return hash
        }
        return 0
    }

    static func ==(_ left: AnnotationAdapter, _ right: AnnotationAdapter) -> Bool {
        return left.title == right.title
    }
}


protocol MapAnnotationReceiver {
    func updateMap(withAnnotations annotations: [MKAnnotation])
}


// MARK: - UIViewController
class MapViewController : UIViewController {

    // MARK: - Constants

    // For cycling thru the states of the tutorial for the viewcontroller
    private enum CategoryTutorialStage {
        case InitialScreen
        case Map
        case Longpress
        case Slider
        case Menu
        case JustAroundMe
        case SearchBeers
        case SearchStyles
        case FavoriteBeers
        case FavoriteBreweries
    }

    let centerLocation = CLLocation(latitude: 39.5, longitude: -98.35)
    let circularAnimationDuration = 5
    let DistanceAroundUserLocation = CLLocationDistance(200000)
    let iphoneFactor = 2
    let radiusDivisor = 4
    let reuseId = "pin"
    let UserLocationName = "My Location"

    // Pointer animation duration
    private let pointerDelay: CGFloat = 0.0
    private let pointerDuration: CGFloat = 1.0

    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()

    // Coredata
    internal let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    internal let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    private let sliderPaddding : CGFloat = 8

    // MARK: - Variables

    internal var creationQueue: BreweryAndBeerCreationProtocol?

    fileprivate var activeMappingStrategy: MapAnnotationProvider? = nil
    internal var floatingAnnotation: MKAnnotation!
    fileprivate var lastSelectedManagedObject : NSManagedObject?
    internal var routedAnnotation: MKAnnotationView?
    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()
    internal var targetLocation: CLLocation?

    // Initialize the tutorial views initial screen
    private var tutorialState: CategoryTutorialStage = .FavoriteBreweries

    // New breweries with styles variable
    internal var breweriesForDisplay: [Brewery] = []

    // MARK: - IBOutlet
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentLocation: UIButton!
    @IBOutlet weak var enableRouting: UISwitch!
    @IBOutlet weak var showLocalBreweries: UISwitch!
    @IBOutlet weak var longPressRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var menu: UIView!
    @IBOutlet weak var menuConstraint: NSLayoutConstraint!
    @IBOutlet weak var numberOfPoints: UILabel!
    @IBOutlet weak var slider: UISlider!


    // Tutorial outlets
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var nextTutorial: UIButton!


    // MARK: - IBAction

    @IBAction func currentLocationTapped(_ sender: UIButton) {
        clearPointFromTargetLocation()
    }

    @IBAction func helpTapped(_ sender: Any) {
        tutorialView.isHidden = false
    }

    @IBAction func menuTapped(_ sender: Any) {
        exposeMenu()
    }

    @IBAction func nextTutorialAction(_ sender: UIButton) {
        // Advance the tutorial state
        switch tutorialState {
        case .InitialScreen:
            tutorialState = .Longpress
        case .Longpress:
            tutorialState = .Map
        case .Map:
            tutorialState = .JustAroundMe
        case .JustAroundMe:
            tutorialState = .Slider
        case .Slider:
            tutorialState = .Menu
        case .Menu:
            tutorialState = .SearchStyles
        case .SearchStyles:
            tutorialState = .SearchBeers
        case .SearchBeers:
            tutorialState = .FavoriteBeers
        case .FavoriteBeers:
            tutorialState = .FavoriteBreweries
        case .FavoriteBreweries:
            tutorialState = .InitialScreen
        }

        // Show tutorial content
        switch tutorialState {
        case .InitialScreen:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "Welcome to Brewery Tour.\nThis app was designed to help you plan a trip to breweries that serve your favorite beer styles.\nPlease step thru this tutorial with the next button.\nDismiss it when you are done.\nAny time you want to bring the tutorial back press Help"

        case .Longpress:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Lets start by long pressing on any location to set a new center for breweries to gather around\n"
            // Adds a circular path to tutorial pointer
            addCircularPathToPointer()
            break

        case .Map:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Select any brewery marker to see it's route.\nClick the heart to favorite a brewery.\nClick on information to bring up the brewery's website."
            // Adds a circular path to tutorial pointer
            addCircularPathToPointer()

        case .JustAroundMe:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "Press 'Just around me' button to return to your home location"

        case .Slider:
            pointer.isHidden = false
            pointer.layer.removeAllAnimations()
            pointer.setNeedsDisplay()
            tutorialText.text = "Move the slider to select how many breweries you want displayed"
            let sliderPoint  = CGPoint(x: slider.frame.origin.x + sliderPaddding , y: slider.frame.midY)
            pointer.center = sliderPoint
            UIView.animateKeyframes(withDuration: TimeInterval(pointerDuration),
                                    delay: TimeInterval(pointerDelay),
                                    options: [ .autoreverse, .repeat ],
                                    animations: { self.pointer.center.x += self.slider.frame.width - self.sliderPaddding},
                                    completion: nil)
            break

        case .Menu:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "Tap Menu on the navigation bar for map options.\nHere you can allow the pointer to show all breweries nearby your target instead of just one style.\nHere you can also disable the green routing line."
            break

        case .SearchStyles:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "At the bottom the 'Search Style' tab allows you to search for all beers and breweries that produce a specific style."
            break

        case .SearchBeers:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "At the bottom the 'Search Beers' tab allows you to search for individual beer names, and see the selected group of beers from the search styles tab."
            break

        case .FavoriteBeers:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "The 'Favorite Beers' tab allows you to see beers you've favorited when you clicked on a beer in the 'Search Beers' tab."
            break

        case .FavoriteBreweries:
            hidePointerAndRemoveAnimation()
            tutorialText.text = "The 'Favorite Breweries' tab allow you to see all the breweries you've favorited on the map. It will also allow you to navigate to them when you tap the brewery name."
            break
        }
    }


    @IBAction func dismissTutorial(_ sender: UIButton) {

        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.MapViewShowTutorial)
        UserDefaults.standard.synchronize()
    }


    @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        // Remove redundant calls to long press
        //mapView.resignFirstResponder()

        // When the user places a pin down allow them to see if they are in
        // local brewery or global brewery mode.
        if  menuConstraint.constant == 0 {
            showLocalBreweries.isOn = true
            exposeMenu()

        }

        // Always set a pin down when user presses down
        // When the pin state is changed delete old pin and replace with new pin
        // When user release drop the pin and save it locally
        switch sender.state {
        case UIGestureRecognizerState.began:

            // Remove old annotation
            if floatingAnnotation != nil {
                mapView.removeAnnotation(floatingAnnotation)
            }

            // Set floating annotation
            let coordinateOnMap = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.title = ""
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


    @IBAction func routingSwitchAction(_ sender: UISwitch) {
        if !sender.isOn {
            mapView.removeOverlays(mapView.overlays)
        }
    }


    @IBAction func showLocalBreweriesAction(_ sender: UISwitch) {
            displayNewStrategyWithNewPoint()
    }

    @IBAction func sliderAction(_ sender: UISlider, forEvent event: UIEvent) {
        let intValue: Int = Int(sender.value)
        numberOfPoints.text = String(intValue)
    }


    @IBAction func sliderTouchUpInside(_ sender: UISlider, forEvent event: UIEvent) {
        touchUpSlider(sender)
    }


    @IBAction func touchUpOutside(_ sender: UISlider) {
        touchUpSlider(sender)
    }


    // MARK: - Functions

    func centerMapOnLocation(location: CLLocation?, radiusInMeters regionRadius: CLLocationDistance?, centerUS: Bool) {

        // User is watching and annotation don't move the screen.
        guard mapView.selectedAnnotations.count == 0 else {
            return
        }
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
            // The distances are in meters
            let coordinateRegion = MKCoordinateRegionMakeWithDistance((location?.coordinate)!,
                                                                      regionRadius!, regionRadius!)
            self.mapView.setRegion(coordinateRegion, animated: true)
            self.mapView.setNeedsDisplay()
        }
    }


    @objc private func clearPointFromTargetLocation() {
        currentLocation.isHidden = true
        guard floatingAnnotation != nil else {
            return
        }
        mapView.removeAnnotation(floatingAnnotation)
        floatingAnnotation = nil
        // Reset back to user true location
        targetLocation = nil
        centerMapOnLocation(location: mapView.userLocation.location, radiusInMeters: DistanceAroundUserLocation, centerUS: false)
        displayNewStrategyWithNewPoint()
    }


    private func compareCoordinates(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
        if a.latitude == b.latitude && a.longitude == b.longitude {
            return true
        }
        return false
    }


    // This stops whatever search is currently running and
    // invokes a new search.
    private func decideOnMappingStrategyAndInvoke(mapViewData: NSManagedObject?) {
        // Decision making to display Breweries Style or Brewery

        // Can't map either strategy as there is no target
        guard targetLocation != nil else {
            return
        }

        let _ = activeMappingStrategy?.endSearch()

        guard !showLocalBreweries.isOn else {
            activeMappingStrategy = AllBreweriesMapStrategy(view: self,
                                                            location: targetLocation!,
                                                            maxPoints: Int(slider.value),
                                                            inputContext: readOnlyContext! )
            return
        }


        if mapViewData is Style {

            activeMappingStrategy = StyleMapStrategy(style: mapViewData as? Style,
                                                     view: self,
                                                     location: targetLocation!,
                                                     maxPoints: Int(slider.value),
                                                     inputContext: readOnlyContext!)

            // Changing stylemapping strategies can occur often, this will,
            // help the processing StyleMapStrategy differentiate which strategy
            // is running.
            // When the StyleMapStrategy sees that it is not the current strategy
            // it will end itself.
            Mediator.sharedInstance().onlyValidStyleStrategy = (activeMappingStrategy as! StyleMapStrategy).runningID

        } else if mapViewData is Brewery {

            activeMappingStrategy = SingleBreweryMapStrategy(b: mapViewData as! Brewery,
                                                       view: self,
                                                       location: targetLocation!)
        }
    }


    // This picks which location to center breweries around.
    internal func decideOnTargetLocation() {
        // Zoom to users location first if we have it.
        // When we first join the mapview and the userlocation has not been set.
        // It will default to 0,0, so we center the location in the US

        // Only do this when target location is nil or this
        // is the temporary centerLocation
        // If target location is non nil we already have a target.
        guard targetLocation == nil || targetLocation == centerLocation else {
            return
        }

        let uninitialzedLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        if mapView.userLocation.coordinate.latitude == uninitialzedLocation.latitude &&
            mapView.userLocation.coordinate.longitude == uninitialzedLocation.longitude {
            targetLocation = centerLocation
        } else {
            targetLocation = mapView.userLocation.location
        }
    }


    // This performs setup prior to deciding on a map strategy
    fileprivate func displayNewStrategyWithNewPoint() {

        // Get new selection
        let mapViewData = Mediator.sharedInstance().getPassedItem()
        // If there is nothing no changes need to be made to the map

        // Stop if there is nothing to display

        // This is stopping the beginning inital user locatin update form happening

        guard mapViewData != nil || showLocalBreweries.isOn ||
            targetLocation == mapView.userLocation.location else {
                return
        }


        // Tells mediator we have selected a targetLocation
        // and to showLocalBreweries.
        if showLocalBreweries.isOn && targetLocation != nil {
            CLGeocoder().reverseGeocodeLocation(targetLocation!)
            { (placemarksarray, error) -> Void in
                guard error == nil else {
                    self.displayAlertWindow(title: "Geocoding Error",
                                            msg: "Failed Please try again ",
                                            actions: [])
                    return
                }
                let placemark: CLPlacemark = (placemarksarray?.first)! as CLPlacemark
                let state = ConvertToFullStateName().fullname(fromAbbreviation: placemark.administrativeArea!)
                Mediator.sharedInstance().select(thisItem: nil, state: state) {
                    (success,msg) -> Void in
                }
            }// end of geocoder completion handler
        }

        decideOnTargetLocation()

        decideOnMappingStrategyAndInvoke(mapViewData: mapViewData)

        // Capture last selection, so we can compare when an update is requested
        lastSelectedManagedObject = mapViewData

        activateIndicatorIfSystemBusy()
    }


    // Show the options menu for 'Show local only' and 'Enable routing' to display.
    @objc internal func exposeMenu() {
        if menuConstraint.constant == 0 {
            showMenu()
        } else {
            shrinkMenu()
        }
    }


    private func showMenu() {
        let maxUIView = maxOf(viewsIn: flattenUIView(menu))
        menuConstraint.constant = (maxUIView.intrinsicContentSize.width)
            + 2 * maxUIView.layoutMargins.left
            + 2 * enableRouting.layoutMargins.left
            + enableRouting.intrinsicContentSize.width
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }


    private func shrinkMenu() {
        menuConstraint.constant = 0
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }



    private func maxOf(viewsIn views: [UIView]) -> UIView {
        let largest = views.max(by:
        { a, b -> Bool in
            return a.intrinsicContentSize.width < b.intrinsicContentSize.width })
        return largest ?? view // Return the largest view in the tree of view or the main view
    }

    
    private func flattenUIView(_ view: UIView) -> [UIView] {
        var allViews: [UIView] = []
        if view.subviews.count == 0 { // If there are no subview return itself
            return [view]
        }

        // Put the original containing view in
        allViews.append(view)

        // Put all child views in
        for subview in view.subviews {
            allViews.append(contentsOf: flattenUIView(subview))
        }
        return allViews
    }


    private func hidePointerAndRemoveAnimation() {
        pointer.isHidden = true
        pointer.layer.removeAllAnimations()
        pointer.setNeedsDisplay()
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


    private func makePointTargetLocation() {
        // Expose the button only when we have pin
        currentLocation.isHidden = false
        Mediator.sharedInstance().setFloating(annotation: floatingAnnotation)
        let location = CLLocation(latitude: floatingAnnotation.coordinate.latitude, longitude: floatingAnnotation.coordinate.longitude)
        targetLocation = location
        displayNewStrategyWithNewPoint()
    }


    private func routedAnnotationIsNot(inArray annotations: [MKAnnotation]) -> Bool {
        if let coordinate = routedAnnotation?.annotation?.coordinate {
            for annotation in annotations {
                if compareCoordinates(a: annotation.coordinate, b: coordinate ) {
                    return false
                }
            }
        }
        return true
    }


    // Dynamically changes the number of breweries shown on map
    private func touchUpSlider(_ sender: UISlider) {
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
        guard mapViewData is Style || showLocalBreweries.isOn  else {
            return
        }
        displayNewStrategyWithNewPoint()
    }


    private func tutorialInitialization() {
        // Tutorial layers
        tutorialState = .FavoriteBreweries
        nextTutorialAction(UIButton())
        // Display tutorial view.
        tutorialView.isHidden = false
        guard UserDefaults.standard.bool(forKey: g_constants.MapViewShowTutorial) == true else {
            tutorialView.isHidden = true
            return
        }
    }


    fileprivate func updateMapRemoveDuplicatesAndPrepareFinalDrawingArray(finalAnnotations: [MKAnnotation]) -> (Set<AnnotationAdapter>, Set<AnnotationAdapter>) {

        // Remove overlays if the Brewery has been remove from
        // the observable set
        if self.routedAnnotationIsNot(inArray: finalAnnotations) {
            self.mapView.removeOverlays(self.mapView.overlays)
        }

        // Decorate old annotations
        var old: [AnnotationAdapter] = [AnnotationAdapter]()
        var oldAnnotations = self.mapView.annotations
        if let index = oldAnnotations.index(where: {$0 === self.floatingAnnotation} ) {
            oldAnnotations.remove(at: index)
        }
        if let index = oldAnnotations.index(where: {$0.title!! == self.UserLocationName} ) {
            oldAnnotations.remove(at: index)
        }
        for a in oldAnnotations {
            old.append(AnnotationAdapter(a))
        }

        //Decorate new annotations
        var new: [AnnotationAdapter] = [AnnotationAdapter]()
        for a in finalAnnotations {
            new.append(AnnotationAdapter(a))
        }

        // Convert arrays to sets to perform set logic
        let oldSet:Set<AnnotationAdapter> = Set<AnnotationAdapter>(old)
        let newSet = Set<AnnotationAdapter>(new)

        // Find intersection
        let intersectSet = oldSet.intersection(newSet)

        let removeSet = oldSet.symmetricDifference(intersectSet)
        let addSet = newSet.symmetricDifference(intersectSet)

        return (removeSet,addSet)
    }


    // MARK: - View Life Cycle Functions

    // Ask user for access to their location
    override func viewDidLoad() {
        super.viewDidLoad()

        // Hide current location butoton
        currentLocation.isHidden = true

        DispatchQueue.main.async{
            self.mapView.showsUserLocation = true
            self.mapView.showsScale = true
            self.mapView.showsCompass = true
        }

        initCoreLoction()

        registerAsBusyObserverWithMediator()

        mapView.addGestureRecognizer(longPressRecognizer)

        // Set slider value and text
        slider.value = Float(Mediator.sharedInstance().lastSliderValue())
        numberOfPoints.text = String(Int(slider.value))

        // If we save a floating annotation from before show it.
        if let annotation = Mediator.sharedInstance().getFloatingAnnotation() {
            floatingAnnotation = annotation
            mapView.addAnnotation(floatingAnnotation)
            makePointTargetLocation()
        }

        // Register with Mediator as Receive contextRefreshes
        Mediator.sharedInstance().registerManagedObjectContextRefresh(self)
    }


    // FIXME remove after testing complete
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        styleFRC = NSFetchedResultsController() // Break access to NSMOContext

    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // FIXME: Test to remove navigation bar filter
        //navigationController?.navigationBar.isTranslucent = true

        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
        
        // Set the function of this screen
        tabBarController?.title = "Go To Website"
        
        // Wondering how we center the map 
        // This functions both sets the targetLocation and display strategy
        displayNewStrategyWithNewPoint()
    }
    
    
    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)
        
        tutorialInitialization()
        // Center on use location
        centerMapOnLocation(location: mapView.userLocation.location,
                            radiusInMeters: DistanceAroundUserLocation,
                            centerUS: false)
    }
}


extension MapViewController: MapAnnotationReceiver {
    // Draw the annotations on the map
    internal func updateMap(withAnnotations annotations: [MKAnnotation]) {
        var finalAnnotations:[MKAnnotation]?

        // Remove excess annotations
        if annotations.count > Int(self.slider.value) {
            finalAnnotations = Array(annotations[0..<Int(self.slider.value)])
        } else {
            finalAnnotations = annotations
        }

        guard finalAnnotations != nil,   // if there are no annotations exit.
            // If the annotations displayed are the same do nothing
            self.arraysAreDifferent(arrayWithFloatingAnnotation: self.mapView.annotations, finalAnnotations!) else {
                // Do nothing annotations are the same
                return
        }
        let (removeSet, addSet) = updateMapRemoveDuplicatesAndPrepareFinalDrawingArray(finalAnnotations: finalAnnotations!)
        // Convert back to MKAnnotations
        let removeArray = convertSetToArrayOfAnnotations(set: removeSet)
        let addArray = convertSetToArrayOfAnnotations(set: addSet)

        if removeSet.count == 0 && addSet.count == 0 &&
            removeSet.first?.title! == self.UserLocationName {
            return
        }
        DispatchQueue.main.async {
            // Add only new annotations, remove old annotations
            // This prevents flashing
            self.mapView.removeAnnotations(removeArray)
            self.mapView.addAnnotations(addArray)

            // Add back out floating annotation we deleted.
            if let floatingAnnotation = self.floatingAnnotation {
                self.mapView.addAnnotation(floatingAnnotation)
            }
        }
    }
}


// MARK: - ReceiveBroadcastManagedObjectContextRefresh

extension MapViewController: ReceiveBroadcastManagedObjectContextRefresh {

    func contextsRefreshAllObjects() {
        //SwiftyBeaver.info("MapViewController.contextsRefreshAllObjects() called")
        //SwiftyBeaver.info("MapViewController now calling endSearch on the attached mapstrategy \(String(describing: activeMappingStrategy))")
        let _ = activeMappingStrategy?.endSearch()
        // FIXME: Should I remove all the annotations.
        // Clear the current annotation on screen.
        mapView.removeAnnotations(mapView.annotations)
    }
}

// MARK: - BusyObserver

extension MapViewController: BusyObserver {

    func registerAsBusyObserverWithMediator() {
        Mediator.sharedInstance().registerForBusyIndicator(observer: self)
    }


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
}


// MARK: - CLLocationManagerDelegate
// Places the placemark for User's current location
extension MapViewController: CLLocationManagerDelegate {
    // When we first start the MapViewController, the initial placement will
    // always be in the middle as it take CLLocationManager a few minutes
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        return
    }


    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        return
    }


    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        // When the cllmanager finally catches the user postion and there is
        // only the center selected point lets remove the center point.
        if targetLocation == centerLocation {
            centerMapOnLocation(location: mapView.userLocation.location,
                                radiusInMeters: CLLocationDistance(DistanceAroundUserLocation), centerUS: false)
        }
        return
    }

}


// MARK: - DismissableTutorial
// Tutorial code.

extension MapViewController : DismissableTutorial {

    // Tutoral Function to plot a circular path for the pointer
    func addCircularPathToPointer() {
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
                                      endAngle:CGFloat(Double.pi)*2,
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


// MARK: - MapViewController Routes FIXME: I'm not a protocol extension what am i

extension MapViewController {

    // Utility function to convert annotation coordinates to MKMapitems
    func convertToMKMapItemThis(_ view: MKAnnotationView) -> MKMapItem {
        return MKMapItem(placemark: MKPlacemark(coordinate: (view.annotation?.coordinate)!))
    }


    // Display the route on map
    func displayRouteOnMap(route: MKRoute){
        mapView.add(route.polyline)
        mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsetsMake(120.0,120.0,120.0,120.0), animated: true)
    }


    /// Render the route line
    internal func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if overlay is MKPolyline {
            polylineRenderer.strokeColor = UIColor.green.withAlphaComponent(0.5)
            polylineRenderer.lineWidth = 3
        }
        return polylineRenderer
    }


    /// Removes all routes from map
    internal func removeRouteOnMap(){

        mapView.removeOverlays(mapView.overlays)
    }
}


// MARK: - MKMapViewDelegate

extension MapViewController : MKMapViewDelegate, AlertWindowDisplaying {

    /// Remove selected callout from map
    internal func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {

        guard view is BeermugAnnotationView else {
            return
        }

        for subview in view.subviews
        {
            subview.removeFromSuperview()
        }
    }


    /// Selecting a Pin, draw the route to this pin and present MKAnnotationView
    internal func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        // Draw green line routing
        if enableRouting.isOn {
            drawRouteLine(onMap: mapView, withAnnotation: view)
        }

        if view.annotation is MKUserLocation || view.annotation === floatingAnnotation {
            // Do not allow selecting the floating pin or user's home pin
            return
        }

        let breweryID = convertAnnotationToObjectID(from: view.annotation!)
        // Fetch object from context
        let selectedBrewery = readOnlyContext?.object(with: breweryID!) as! Brewery
        let breweryAnnotation = BreweryAnnotation(brewery: selectedBrewery)

        // Create a callout
        let views = Bundle.main.loadNibNamed("BreweryCustomCallout", owner: nil, options: nil)
        let calloutView = views?[0] as! BreweryCustomCalloutView
        setup(calloutView, with: breweryAnnotation, with: view)

        // Attach favoriting action on FavoriteImage.
        let favoriteButton = FavoriteUIButton(frame: calloutView.favoriteImage.frame)
        favoriteButton.brewery = selectedBrewery
        favoriteButton.favoriteImageView = calloutView.favoriteImage
        favoriteButton.addTarget(self, action: #selector(changeFavoriteStatusOnBrewery(sender:)), for: .touchUpInside)
        calloutView.addSubview(favoriteButton)
        favoriteButton.objectID = breweryID

        // Set the callout offset from theview
        calloutView.center = CGPoint(x: view.bounds.size.width / 2, y: -calloutView.bounds.size.height*0.52)
        view.addSubview(calloutView)
        mapView.setCenter((view.annotation?.coordinate)!, animated: true)
    }


    /// Setup the values for the custom callout view
    private func setup(_ calloutView: BreweryCustomCalloutView,
                       with brewery: BreweryAnnotation,
                       with view: MKAnnotationView) {

        calloutView.breweryName.text = brewery.breweryName!
        calloutView.breweryWebSite.text = "\(brewery.breweryWebsite ?? "")"
        if brewery.favorite ?? false {
            calloutView.favoriteImage.image = #imageLiteral(resourceName: "favorite")
        } else {
            calloutView.favoriteImage.image = #imageLiteral(resourceName: "unfavorite")
        }

        // Set a a button on the weblink so the user can view the webpage.
        let webButton = WebpageUIButton(frame: calloutView.breweryWebSite.frame)
        if let str : String = (view.annotation?.subtitle)!,
            let destinationUrl: URL = URL(string: str) {
            webButton.url = destinationUrl
            webButton.addTarget(self, action: #selector(tryToOpenWebpage(sender:)), for: .touchUpInside)
            calloutView.addSubview(webButton)
        }
    }


    // When a favorite image is clicked toggle status.
    @objc private func changeFavoriteStatusOnBrewery(sender: FavoriteUIButton) {
        if !(sender.brewery?.favorite ?? true) {
            sender.brewery?.favorite = true
            sender.favoriteImageView?.image = #imageLiteral(resourceName: "favorite")
        } else {
            sender.brewery?.favorite = false
            sender.favoriteImageView?.image = #imageLiteral(resourceName: "unfavorite")
        }
        sender.favoriteImageView?.setNeedsDisplay()
        saveFavoriteStatus(withObjectID: sender.objectID!, favoriteStatus: (sender.brewery?.favorite)!)
    }


    private func drawRouteLine(onMap map: MKMapView, withAnnotation view: MKAnnotationView) {

        // if user elected to disable green line routing
        guard enableRouting.isOn else {
            return
        }

        // Save the routed annotation
        routedAnnotation = view

        // Our location
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: mapView.userLocation.coordinate))

        // The selected brewery destination
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

            guard let routeResponse = response?.routes else {

                // No car routes found, Prompt with a warning window
                self.displayAlertWindow(title: "No Routes", msg: "There are no routes available.")
                SwiftyBeaver.error("There were no routes available")
                return
            }

            self.removeRouteOnMap()
            // Need to sort to just the fastest travel time one
            let quickestRoute : MKRoute = routeResponse.sorted(by: {$0.expectedTravelTime < $1.expectedTravelTime})[0]
            self.displayRouteOnMap(route: quickestRoute)
        }
    }


    func saveFavoriteStatus(withObjectID objectID: NSManagedObjectID, favoriteStatus: Bool) {

        // Save favorite status and update map
        container?.performBackgroundTask() {
            (context) -> Void in
            (context.object(with: objectID) as! Brewery).favorite = favoriteStatus
            context.performAndWait {

                do {
                    try context.save()
                } catch _ {
                    SwiftyBeaver.error("MapViewController error saving favorite status.")
                    self.displayAlertWindow(title: "Error", msg: "Sorry there was an error toggling your favorite brewery, \nplease try again")
                }
            }
        }
    }


    // Wraps conditional logic around webpage opening, to prevent malformed url
    @objc func tryToOpenWebpage(sender : Any) {

        if let url = (sender as? WebpageUIButton)?.url,
            UIApplication.shared.canOpenURL(url) {

            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }


    /// Find brewery objectid by using name in annotation
    private func convertAnnotationToObjectID(from: MKAnnotation) -> NSManagedObjectID? {

        guard let myTitle = from.title! else {
            return nil
        }

        let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "name = %@", myTitle )

        do {
            let breweries = try readOnlyContext?.fetch(request)
            if let brewery = breweries?.first {
                return brewery.objectID
            }
        } catch {
            SwiftyBeaver.error("MapViewController Error converting Annotation to NSManagedObjectID")
            displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again")
        }
        return nil
    }


    // This formats the pins and beers mugs on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? BeermugAnnotationView

        var foundBrewery: Brewery?

        if let objectID = convertAnnotationToObjectID(from: annotation) {
            foundBrewery = readOnlyContext?.object(with: objectID) as? Brewery
        }

        // Based on the incoming annotationView let's change this pinView
        return MakePinView.sharedInstance().makePinOrBeerMugViewOnMap(fromAnnotationView: pinView,
                                                                   fromAnnotation: annotation,
                                                                   withUserLocation: mapView.userLocation,
                                                                   floatingAnnotation: floatingAnnotation,
                                                                   reuseID: reuseId,
                                                                   brewery: foundBrewery)
    }
}


// MARK: - NSFetchedResultsControllerDelegate

extension MapViewController : NSFetchedResultsControllerDelegate {

    // Used for when style is updated with new breweries
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        // Save all breweries for display the debouncing function will ameliorate the excessive calls to this.
        SwiftyBeaver.info("MapViewController.controllerDidChangeContent Called")
        breweriesForDisplay = (controller.fetchedObjects?.first as! Style).brewerywithstyle?.allObjects as! [Brewery]
    }
}


// MARK: - Fileprivate helper methods

extension MapViewController {

    /// Activate indicator if system is busy
    fileprivate func activateIndicatorIfSystemBusy() {

        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
    }


    /// Compares arrays of MKAnnotations and returns true when they are different
    ///
    /// - parameters:
    ///     - arrayWithFloatingAnnotayion: an array with the users location (floating annotation)
    ///     - b: other array to compare to
    /// - returns:
    ///     - `true` if the array are different
    fileprivate func arraysAreDifferent(arrayWithFloatingAnnotation: [MKAnnotation], _ b: [MKAnnotation]) -> Bool {

        var a = arrayWithFloatingAnnotation
        if !a.isEmpty {
            a.removeLast() // remove floating annotation
        }

        if a.count == 0 && b.count == 0 {
            return false
        }

        guard a.count == b.count, a.count > 0 && b.count > 0 else { // array must be of similar length non zero
            return true
        }

        for i in 0..<a.count {
            if a[i].coordinate.latitude != b[i].coordinate.latitude ||
                a[i].coordinate.longitude != b[i].coordinate.longitude {
                return true
            }
        }
        return false
    }


    /// Returns an array of Annotations from a set.
    fileprivate func convertSetToArrayOfAnnotations(set :Set<AnnotationAdapter>) -> [MKAnnotation] {

        return set.flatMap({$0.annotation})
    }
}




