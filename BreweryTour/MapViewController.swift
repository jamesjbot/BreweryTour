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

// Helper Adapter class to sort/filter annotations
fileprivate class NewMyAnnotation: NSObject {
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
        if object is NewMyAnnotation {
            return title == (object as! NewMyAnnotation).title
        }
        return false
    }

    override var hashValue: Int {
        if let hash = title?.hashValue {
            return hash
        }
        return 0
    }

    static func ==(left: NewMyAnnotation, right: NewMyAnnotation) -> Bool {
        return left.title == right.title
    }
}


class MapViewController : UIViewController {

    // MARK: - Constants
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

    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()

    // Coredata
    internal let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    internal let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    private let sliderPaddding : CGFloat = 8

    // MARK: - Variables

    fileprivate weak var activeMappingStrategy: MapStrategy? = nil
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


    // Tutorial
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
        UserDefaults.standard.set(false, forKey: g_constants.MapViewTutorial)
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

    private func activateIndicatorIfSystemBusy() {
        // Activate indicator if system is busy
        if Mediator.sharedInstance().isSystemBusy() {
            DispatchQueue.main.async {
                self.activityIndicator.startAnimating()
            }
        }
    }


    private func arraysAreDifferent(a copy: [MKAnnotation], b: [MKAnnotation]) -> Bool {
        var a = copy
        if !copy.isEmpty {
            a.removeLast() // remove floatingannotation
        }
        guard a.count == b.count else {
            return true
        }

        // They are either both zero or both not zero
        guard a.count != 0 && b.count != 0 else {
            return false
        }

        for (i,_) in a.enumerated() {
            if a[i].coordinate.latitude != b[i].coordinate.latitude ||
                a[i].coordinate.longitude != b[i].coordinate.longitude {
                return true
            }
        }
        return false
    }


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

        activeMappingStrategy?.endSearch()

        guard !showLocalBreweries.isOn else {
            activeMappingStrategy = AllBreweriesMapStrategy(view: self,
                                                            location: targetLocation!,
                                                            maxPoints: Int(slider.value))
            return
        }


        if mapViewData is Style {

            activeMappingStrategy = StyleMapStrategy(s: mapViewData as? Style,
                                                     view: self,
                                                     location: targetLocation!,
                                                     maxPoints: Int(slider.value))

            // Changing stylemapping strategies can occur often, this will,
            // help the processing StyleMapStrategy differentiate which strategy
            // is running.
            // When the StyleMapStrategy sees that it is not the current strategy
            // it will end itself.
            Mediator.sharedInstance().onlyValidStyleStrategy = (activeMappingStrategy as! StyleMapStrategy).runningID!

        } else if mapViewData is Brewery {

            activeMappingStrategy = BreweryMapStrategy(b: mapViewData as! Brewery,
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
    internal func displayNewStrategyWithNewPoint() {

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
                let state = ConvertToFullStateName().fullname(placemark.administrativeArea!)
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
        if UserDefaults.standard.bool(forKey: g_constants.MapViewTutorial) {
            // Do nothing because the tutorial will show automatically.
            tutorialView.isHidden = false

        } else {
            tutorialView.isHidden = true
        }
    }


    private func updateExtraction(a set :Set<NewMyAnnotation>) -> [MKAnnotation] {
        var returnArray = [MKAnnotation]()
        for annotation in set {
            returnArray.append(i.annotation!)
        }
        return returnArray
    }


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
            self.arraysAreDifferent(a: self.mapView.annotations, b: finalAnnotations!) else {
                // Do nothing annotations are the same
                return
        }
        let (removeSet, addSet) = updateMapRemoveDuplicatesAndPrepareFinalDrawingArray(finalAnnotations: finalAnnotations!)
        // Convert back to MKAnnotations
        let removeArray = self.updateExtraction(a: removeSet)
        let addArray = self.updateExtraction(a: addSet)

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


    fileprivate func updateMapRemoveDuplicatesAndPrepareFinalDrawingArray(finalAnnotations: [MKAnnotation]) -> (Set<NewMyAnnotation>, Set<NewMyAnnotation>) {

        // Remove overlays if the Brewery has been remove from
        // the observable set
        if self.routedAnnotationIsNot(inArray: finalAnnotations) {
            self.mapView.removeOverlays(self.mapView.overlays)
        }

        // Decorate old annotations
        var old: [NewMyAnnotation] = [NewMyAnnotation]()
        var oldAnnotations = self.mapView.annotations
        if let index = oldAnnotations.index(where: {$0 === self.floatingAnnotation} ) {
            oldAnnotations.remove(at: index)
        }
        if let index = oldAnnotations.index(where: {$0.title!! == self.UserLocationName} ) {
            oldAnnotations.remove(at: index)
        }
        for a in oldAnnotations {
            old.append(NewMyAnnotation(a))
        }

        //Decorate new annotations
        var new: [NewMyAnnotation] = [NewMyAnnotation]()
        for a in finalAnnotations {
            new.append(NewMyAnnotation(a))
        }

        // Convert arrays to sets to perform set logic
        let oldSet:Set<NewMyAnnotation> = Set<NewMyAnnotation>(old)
        let newSet = Set<NewMyAnnotation>(new)

        // Find intersection
        let intersectSet = oldSet.intersection(newSet)

        let removeSet = oldSet.symmetricDifference(intersectSet)
        let addSet = newSet.symmetricDifference(intersectSet)

        return (removeSet,addSet)
    }


    // MARK: - View Life Cycle functions

    // Ask user for access to their location
    override func viewDidLoad(){
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









