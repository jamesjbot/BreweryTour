//
//  JustUserAndFloatingPinAnnotationView.swift
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

class JustUserAndFloatingPinAnnotationView: MKPinAnnotationView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        frame.size.width = frame.size.width * 2
    }
    
    init(annot: MKAnnotation, reuse: String!) {
        super.init(annotation: annot, reuseIdentifier: reuse)
    }
}
