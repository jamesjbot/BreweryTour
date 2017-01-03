//
//  MyPinAnnotationView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/2/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import UIKit
import MapKit

class MyPinAnnotationView: MKPinAnnotationView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame.size.width = self.frame.size.width * 2
    }

    init(annot: MKAnnotation, reuse: String!) {
        super.init(annotation: annot, reuseIdentifier: reuse)
    }


}
