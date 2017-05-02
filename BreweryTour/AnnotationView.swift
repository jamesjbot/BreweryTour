//
//  AnnotationView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 5/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import MapKit

class AnnotationView: MKAnnotationView {

    // Detects hits on the Annotation view
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if (hitView != nil)
        {
            self.superview?.bringSubview(toFront: self)
        }
        return hitView
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let rect = self.bounds;
        var isInside: Bool = rect.contains(point);
        if(!isInside)
        {
            for view in self.subviews
            {
                isInside = view.frame.contains(point);
                if isInside
                {
                    break;
                }
            }
        }
        return isInside;
    }
}
