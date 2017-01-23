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
    let centerLocation = CLLocation(latitude: 39.5, longitude: -98.35)
    let circularAnimationDuration = 5
    let iphoneFactor = 2
    let radiusDivisor = 4
    let reuseId = "pin"

    // Pointer animation duration
    private let pointerDelay: CGFloat = 0.0
    private let pointerDuration: CGFloat = 0.5

    // For cycling thru the states of the tutorial for the viewcontroller
    private enum CategoryTutorialStage {
        case Map
        case Longpress
        case Slider
    }

    // Location manager allows us access to the user's location
    private let locationManager = CLLocationManager()

    // Coredata
    internal let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    internal let readOnlyContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container.viewContext

    private let sliderPaddding : CGFloat = 8

    // MARK: Variables

    fileprivate weak var activeMappingStrategy: MapStrategy? = nil
    internal var floatingAnnotation: MKAnnotation!
    fileprivate var lastSelectedManagedObject : NSManagedObject?
    internal var routedAnnotation: MKAnnotationView?
    fileprivate var styleFRC: NSFetchedResultsController<Style> = NSFetchedResultsController<Style>()
    fileprivate var targetLocation: CLLocation?

    // Initialize the tutorial views initial screen
    private var tutorialState: CategoryTutorialStage = .Map

    // New breweries with styles variable
    internal var breweriesForDisplay: [Brewery] = []

    // MARK: IBOutlet

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentLocation: UIButton!
    @IBOutlet weak var longPressRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var numberOfPoints: UILabel!
    @IBOutlet weak var slider: UISlider!

    // Tutorial
    @IBOutlet weak var pointer: CircleView!
    @IBOutlet weak var tutorialText: UITextView!
    @IBOutlet weak var tutorialView: UIView!
    @IBOutlet weak var nextTutorial: UIButton!


    // MARK: IBAction

    @IBAction func currentLocationTapped(_ sender: UIButton) {
        clearPointFromTargetLocation()
    }


    @IBAction func nextTutorialAction(_ sender: UIButton) {
        // Advance the tutorial state
        switch tutorialState {
        case .Map:
            tutorialState = .Longpress
        case .Longpress:
            tutorialState = .Slider
        case .Slider:
            tutorialState = .Map
        }

        // Show tutorial content
        switch tutorialState {
        case .Map:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Select any brewery marker to see it's route.\nClick the heart to favorite a brewery.\nClick on information to bring up brewery website."
            // Adds a circular path to tutorial pointer
            addCircularPathToPointer()

        case .Longpress:
            pointer.isHidden = false
            pointer.setNeedsDisplay()
            tutorialText.text = "Hold down on any location to set a new\ncenter for breweries to gather around\nPress Reset to home to return to your location"
            // Adds a circular path to tutorial pointer
            addCircularPathToPointer()
            break

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
        }

    }


    @IBAction func dismissTutorial(_ sender: UIButton) {

        tutorialView.isHidden = true
        UserDefaults.standard.set(false, forKey: g_constants.MapViewTutorial)
        UserDefaults.standard.synchronize()
    }


    @IBAction func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        // Remove redundant calls to long press
        mapView.resignFirstResponder()

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


    @objc private func clearPointFromTargetLocation() {
        currentLocation.isHidden = true
        guard floatingAnnotation != nil else {
            return
        }
        mapView.removeAnnotation(floatingAnnotation)
        floatingAnnotation = nil
        // Reset back to user true location
        targetLocation = nil
        displayNewStrategyWithNewPoint()
    }


    private func compareCoordinates(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
        if a.latitude == b.latitude && a.longitude == b.longitude {
            return true
        }
        return false
    }


    private func createCurrentLocationButton() {
        let userLocationButton = UIBarButtonItem(title: "Current location", style: .plain, target: self, action: #selector(clearPointFromTargetLocation))
        self.navigationItem.setRightBarButtonItems([userLocationButton], animated: true)
    }


    private func decideOnMappingStrategyAndInvoke(mapViewData: NSManagedObject) {
        // Decision making to display Breweries Style or Brewery

        activeMappingStrategy?.endSearch()

        if mapViewData is Style {

            activeMappingStrategy = StyleMapStrategy(s: mapViewData as! Style,
                                                     view: self,
                                                     location: targetLocation!,
                                                     maxPoints: Int(slider.value))
            Mediator.sharedInstance().onlyValidStyleStrategy = (activeMappingStrategy as! StyleMapStrategy).runningID!

        } else if mapViewData is Brewery {

            activeMappingStrategy = BreweryMapStrategy(b: mapViewData as! Brewery,
                                                       view: self,
                                                       location: targetLocation!)
            
        }
    }


    internal func displayNewStrategyWithNewPoint() {

        // Get new selection
        let mapViewData = Mediator.sharedInstance().getPassedItem()
        // If there is nothing no changes need to be made to the map
        guard mapViewData != nil else {
            return
        }

        setTargetLocationWhenTargetLocationIsNil()

        decideOnMappingStrategyAndInvoke(mapViewData: mapViewData!)

        // Capture last selection, so we can compare when an update is requested
        lastSelectedManagedObject = mapViewData

        activateIndicatorIfSystemBusy()
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


    private func isAnnotation(inArray: [MKAnnotation]) -> Bool {
        if let coordinate = routedAnnotation?.annotation?.coordinate {
            for i in inArray {
                if compareCoordinates(a: i.coordinate, b: coordinate ) {
                    return true
                }
            }
        }
        return false
    }


    private func makePointTargetLocation() {
        // Expose the button only when we have pin
        currentLocation.isHidden = false
        Mediator.sharedInstance().setFloating(annotation: floatingAnnotation)
        let location = CLLocation(latitude: floatingAnnotation.coordinate.latitude, longitude: floatingAnnotation.coordinate.longitude)
        targetLocation = location
        displayNewStrategyWithNewPoint()
    }
    

    private func setTargetLocationWhenTargetLocationIsNil() {
        // Zoom to users location first if we have it.
        // When we first join the mapview and the userlocation has not been set.
        // It will default to 0,0, so we center the location in the US

        // Only do these when target location is nil or this 
        // is the temporary centerLocation
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
        guard mapViewData is Style else {
            return
        }

        displayNewStrategyWithNewPoint()
    }


    private func tutorialInitialization() {
        // Tutorial layers
        tutorialState = .Slider
        nextTutorialAction(UIButton())
        // Display tutorial view.
        if UserDefaults.standard.bool(forKey: g_constants.MapViewTutorial) {
            // Do nothing because the tutorial will show automatically.
            tutorialView.isHidden = false

        } else {
            tutorialView.isHidden = true
        }
    }


    // Draw the annotations on the map
    internal func updateMap(withAnnotations b: [MKAnnotation]) {

        if !isAnnotation(inArray: b) {
            mapView.removeOverlays(mapView.overlays)
        }

        // If the annotation displayed are the same do nothing
        guard arraysAreDifferent(a: mapView.annotations, b: b) else {
            // Do nothing annotations are the same
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


    // MARK: - View Life Cycle functions

    // Ask user for access to their location
    override func viewDidLoad(){
        super.viewDidLoad()

        currentLocation.isHidden = true

        DispatchQueue.main.async{
            self.mapView.showsUserLocation = true
            self.mapView.showsScale = true
            self.mapView.showsCompass = true
        }

        initCoreLoction()

        registerAsBusyObserverWithMediator()

        mapView.addGestureRecognizer(longPressRecognizer)

        createCurrentLocationButton()

        // Set slider value and text
        slider.value = Float(Mediator.sharedInstance().lastSliderValue())
        numberOfPoints.text = String(Int(slider.value))

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

        displayNewStrategyWithNewPoint()
    }


    override func viewDidAppear(_ animated : Bool) {
        super.viewDidAppear(animated)

        tutorialInitialization()
    }
}



