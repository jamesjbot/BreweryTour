//
//  MapViewControllerExtensions.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/21/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import CoreData
import MapKit

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


// MARK: - MapViewController Routes

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
}


// MARK: - MKMapViewDelegate

extension MapViewController : MKMapViewDelegate {

    // Remove selected callout
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view is BeermugAnnotationView {
            for subview in view.subviews
            {
                subview.removeFromSuperview()
            }
        }
    }

    // Selecting a Pin, draw the route to this pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        // Draw green line routing
        if enableRouting.isOn {
            drawRouteLine(onMap: mapView, withAnnotation: view)
        }

        if view.annotation is MKUserLocation || view.annotation === floatingAnnotation {
            // Do not allow the selection floating pin or user's home pin
            return
        }

        let breweryID = convertAnnotationToObjectID(by: view.annotation!)
        // Fetch object from context
        let selectedBrewery = readOnlyContext?.object(with: breweryID!) as! Brewery
        let breweryAnnotation = BreweryAnnotation(brewery: selectedBrewery)

        // Create a callout
        let views = Bundle.main.loadNibNamed("BreweryCustomCallout", owner: nil, options: nil)
        let calloutView = views?[0] as! BreweryCustomCalloutView
        calloutView.breweryName.text = breweryAnnotation.breweryName!
        calloutView.breweryWebSite.text = "\(breweryAnnotation.breweryWebsite ?? "")"
        if breweryAnnotation.favorite ?? false {
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
        // Disable green line routing
        guard enableRouting.isOn else {
            return
        }

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


    func saveFavoriteStatus(withObjectID objectID: NSManagedObjectID, favoriteStatus: Bool) {
        // Save favorite status and update map
        container?.performBackgroundTask(){
            (context) -> Void in
            (context.object(with: objectID) as! Brewery).favorite = favoriteStatus
            context.performAndWait {
                do {
                    try context.save()
                } catch _ {
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


    //Find brewery objectid by using name in annotation
    fileprivate func convertAnnotationToObjectID(by: MKAnnotation) -> NSManagedObjectID? {
        guard let myTitle = by.title! else {
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
            displayAlertWindow(title: "Error", msg: "Sorry there was an error, \nplease try again")
        }
        return nil
    }

    // This formats the pins and beers mugs on the map 
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? BeermugAnnotationView

        var foundBrewery: Brewery?

        if let objectID = convertAnnotationToObjectID(by: annotation) {
             foundBrewery = readOnlyContext?.object(with: objectID) as? Brewery
        }

        // Based on the incoming annotationView let change this pinView
        let annotationView =
            MakePinView.sharedInstance().makePinOrBeerMugViewOnMap(fromAnnotationView: pinView,
                                                                  fromAnnotation: annotation,
                                                                  withUserLocation: mapView.userLocation,
                                                                  floatingAnnotation: floatingAnnotation,
                                                                  reuseID: reuseId,
                                                                  brewery: foundBrewery)
        return annotationView
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









