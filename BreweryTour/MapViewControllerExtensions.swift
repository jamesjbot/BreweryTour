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
        displayNewStrategyWithNewPoint()
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


    // This formats the pins and calloutAccessory views on the map
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {

        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MyAnnotationView

        var foundBrewery: Brewery?

        if let objectID = convertAnnotationToObjectID(by: annotation) {
             foundBrewery = readOnlyContext?.object(with: objectID) as? Brewery
        }

        // Based on the incoming annotationView let change this pinView
        let annotationView =  MakePinView.sharedInstance().makePinView(fromAnnotationView: pinView,
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









