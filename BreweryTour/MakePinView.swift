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

    
    internal func makePinView(fromAnnotationView: MKAnnotationView?,
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

        // Process 1 & 2 MkAnnotations
        if annotation is MKUserLocation || annotation === floatingAnnotation {
            // Just pins
            guard let fromAnnotationView = fromAnnotationView,
                    fromAnnotationView is MKPinAnnotationView else {
                return createPinAnnotationView(annotation: annotation,
                                           reuseID: reuseID,
                                           isfloatingAnnotation: annotation === floatingAnnotation)
            }
            // Modify the dequeued MKAnnotationView
            if annotation === floatingAnnotation {
                (fromAnnotationView as! MKPinAnnotationView).pinTintColor = UIColor.magenta
            } else {
                (fromAnnotationView as! MKPinAnnotationView).pinTintColor = UIColor.black
            }
            return fromAnnotationView

        } else { // Regular beer location, process 3 MKAnnotations

            guard let fromAnnotationView = fromAnnotationView else {
                return createMKAnnnotationView(annotation: annotation, reuseID: reuseID, brewery: brewery)
            }
            return fromAnnotationView // no need to change the image it's already a beer
        }
    }


    private func createPinAnnotationView(annotation: MKAnnotation, reuseID: String, isfloatingAnnotation: Bool) -> MKPinAnnotationView {
        let pinView = MyPinAnnotationView(annot: annotation, reuse: reuseID)
        if isfloatingAnnotation {
            pinView.pinTintColor = UIColor.magenta
            return pinView
        } else { // This is userlocation
            pinView.pinTintColor = UIColor.black
            return pinView
        }
    }


    private func createMKAnnnotationView(annotation: MKAnnotation, reuseID: String, brewery: Brewery?) -> MKAnnotationView {
        let mkView = MyAnnotationView(annot: annotation, reuse: reuseID, brewery: brewery)
        return mkView
    }

}
