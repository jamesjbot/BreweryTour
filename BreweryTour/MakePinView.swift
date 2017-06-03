
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

    // Return the MKAnnotationView for the map based on what is needed.
    internal func makePinOrBeerMugViewOnMap(
                              fromAnnotationView oldPinView: MKAnnotationView?,
                              fromAnnotation inputAnnotation: MKAnnotation,
                              withUserLocation: MKUserLocation,
                              floatingAnnotation: MKAnnotation?,
                              reuseID: String,
                              brewery: Brewery?) -> MKAnnotationView {

        // Return types: What kind of oldPinViews (dequeued MKAnnotationViews) could we have
        // 1) an MKPinAnnotationView
        // 2) an MKAnnotationView
        // 3) Neither of these Views (nil need to create it based on input annotation type)

        // Input annotation types: What kind of MKAnnotations do we have to map
        // Note: Here cases 1 and 2 use the same kind of pin annotation
        // 1) MKUserLocation
        // 2) FloatingLocation
        // 3) Regular beer location

        // Switch on type of Annotation we are trying to map
        // Process Case 1 & Case 2 MkAnnotations (MKUserLocation && FloatingLocation)
        if inputAnnotation is MKUserLocation || inputAnnotation === floatingAnnotation {
            // Just user and floating pins.

            // We must have an MKAnnotationView and be an MKPinAnnotationView
            guard let localOldPinView = oldPinView,
                oldPinView is MKPinAnnotationView else {
                    // Else we do not have a reusable MKAnnotationView
                    // Create a new User Pin Annotation or floating annotation view
                    return createUserPinAnnotationView(annotation: inputAnnotation,
                                                       reuseID: reuseID,
                                                       isfloatingAnnotation: inputAnnotation === floatingAnnotation)
            }
            
            // Modify the dequeued MKAnnotationView (oldPinView)
            return modifyColorOf(MKAnnotationPinView: localOldPinView,
                                 basedOn: inputAnnotation,
                                 withSelectedAnnotation: floatingAnnotation)

        } else { // Process Case 3 MKAnnotations (Regular brewery location)

            guard let oldPinView = oldPinView else {
                return createBeermugAnnnotationView(withAnnotation: inputAnnotation,
                                                    reuseID: reuseID,
                                                    brewery: brewery)
            }
            return oldPinView // no need to change the image it's already a beer mug
        }
    }

    // Modifies the color of a Dequeued MKAnnotationPinView that represent the center of 
    // where the user wants beer locations clustered around.
    private func modifyColorOf(MKAnnotationPinView oldPinView: MKAnnotationView,
                               basedOn annotation: MKAnnotation,
                               withSelectedAnnotation floatingAnnotation: MKAnnotation?) -> MKPinAnnotationView {
        assert(oldPinView is MKPinAnnotationView)
        let pinView = oldPinView as? MKPinAnnotationView
        if annotation === floatingAnnotation {
            pinView?.pinTintColor = UIColor.magenta
        } else {
            pinView?.pinTintColor = UIColor.black
        }
        return pinView!
    }


    // Creates AnnotationView with pins
    private func createUserPinAnnotationView(annotation: MKAnnotation,
                                             reuseID: String,
                                             isfloatingAnnotation: Bool) -> MKPinAnnotationView {
        let pinView = JustUserAndFloatingPinAnnotationView(annot: annotation, reuse: reuseID)
        if isfloatingAnnotation {
            pinView.pinTintColor = UIColor.magenta
        } else { // This is userlocation
            pinView.pinTintColor = UIColor.black
        }
        return pinView

    }

    // Creates AnnotationView with little beer mugs
    private func createBeermugAnnnotationView(withAnnotation: MKAnnotation,
                                              reuseID: String,
                                              brewery: Brewery?) -> MKAnnotationView {
        return BeermugAnnotationView(annot: withAnnotation,
                                           reuse: reuseID,
                                           brewery: brewery,
                                           favorite: (brewery?.favorite)!)
    }

}
