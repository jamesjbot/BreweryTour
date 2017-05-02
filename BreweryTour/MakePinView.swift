
//
//  MakePinView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/22/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import MapKit

class MakePinView {


    // MARK: - Singleton Implementation
    private init(){
    }

    internal class func sharedInstance() -> MakePinView {
        struct Singleton {
            static var sharedInstance = MakePinView()
        }
        return Singleton.sharedInstance
    }

    
    internal func makePinOrBeerMugViewOnMap(fromAnnotationView oldPinView: MKAnnotationView?,
                              fromAnnotation annotation: MKAnnotation,
                              withUserLocation: MKUserLocation,
                              floatingAnnotation: MKAnnotation?,
                              reuseID: String,
                              brewery: Brewery?) -> MKAnnotationView {
        // The states are 
        // What kind of MKAnnotationViews can we have
        // 1) an MKPinAnnotationView
        // 2) an MKAnnotationView
        // 3) Neither of the View (nil need to create it based on annotation)

        // What kind of MKAnnotation could I have
        // Here 1 and 2 use the same kind of pin annotation
        // 1) MKUserLocation
        // 2) FloatingLocation
        // 3) Regular beer location

        // Process 1 & 2 MkAnnotations (MKUserLocation && FloatingLocation)
        if annotation is MKUserLocation || annotation === floatingAnnotation {
            // Just user and floating pins pins
            // FIXME: remove this dead code.
            // What is this actually doing now
            guard let localOldPinView = oldPinView,
                // We have a an MKAnnotationView
                    oldPinView is MKPinAnnotationView else {
                        // We do not have an old pin
                        // Why are we trying to make an oldPinView again
                        //return localOldPinView
                        //fatalError()
                        //return
                        // Create a new BeerMug Annotation
                        //If the annotation is a user it should never be a beer
                return createUserPinAnnotationView(annotation: annotation,
                                               reuseID: reuseID,
                                               isfloatingAnnotation: annotation === floatingAnnotation)
            }
            
            // Modify the dequeued MKAnnotationView (oldPinView)
            if annotation === floatingAnnotation {
                (oldPinView as! MKPinAnnotationView).pinTintColor = UIColor.magenta
            } else {
                (oldPinView as! MKPinAnnotationView).pinTintColor = UIColor.black
            }
            return oldPinView!

        } else { // Regular beer location, process 3 MKAnnotations

            guard let oldPinView = oldPinView else {
                return createBeermugAnnnotationView(annotation: annotation, reuseID: reuseID, brewery: brewery)
            }
            return oldPinView // no need to change the image it's already a beer
        }
    }

    // Creates AnnotationView with pins
    private func createUserPinAnnotationView(annotation: MKAnnotation, reuseID: String, isfloatingAnnotation: Bool) -> MKPinAnnotationView {
        let pinView = JustUserAndFloatingPinAnnotationView(annot: annotation, reuse: reuseID)
        if isfloatingAnnotation {
            pinView.pinTintColor = UIColor.magenta
            return pinView
        } else { // This is userlocation
            pinView.pinTintColor = UIColor.black
            return pinView
        }
    }

    // Creates AnnotationView with little beer mugs
    private func createBeermugAnnnotationView(annotation: MKAnnotation, reuseID: String, brewery: Brewery?) -> MKAnnotationView {
        let mkView = BeermugAnnotationView(annot: annotation,
                                      reuse: reuseID,
                                      brewery: brewery,
                                      favorite: (brewery?.favorite)!)
        return mkView
    }

}
