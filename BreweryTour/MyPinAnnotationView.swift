//
//  MyPinAnnotationView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/2/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//
/*
    This is a custom MKPinAnnotation for our map
 */

import UIKit
import MapKit

class MyPinAnnotationView: MKPinAnnotationView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        frame.size.width = frame.size.width * 2
    }


    init(annot: MKAnnotation, reuse: String!) {
        super.init(annotation: annot, reuseIdentifier: reuse)
        // Format annotation callouts here
        tintColor = UIColor.red

        // Set the information icon on the right button
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        annotation = annotation
    }

    
    func setBrewery(_ brewery: Brewery) -> MyPinAnnotationView {
        // Set the favorite icon on pin
        let localButton = UIButton(type: .contactAdd)
        var tempImage : UIImage!

        if brewery.favorite == true {
            tempImage = UIImage(named: "small_heart_icon.png")?.withRenderingMode(.alwaysOriginal)

        } else {
            tempImage = UIImage(named: "small_heart_icon_black_white_line_art.png")?.withRenderingMode(.alwaysOriginal)
        }

        localButton.setImage(tempImage, for: .normal)
        leftCalloutAccessoryView = localButton
        return self
    }


}
