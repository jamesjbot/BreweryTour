//
//  MyAnnotationView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/22/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import UIKit
import MapKit

class BeermugAnnotationView: MKAnnotationView {

    var brewery: Brewery?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        frame.size.width = frame.size.width * 2
    }


    init(annot: MKAnnotation, reuse: String!, brewery: Brewery?, favorite: Bool) {
        super.init(annotation: annot, reuseIdentifier: reuse)
        canShowCallout = false
        // Resize image
        // Pin image is the beer image
        let pinImage = #imageLiteral(resourceName: "PinImage")
        let size = CGSize(width: 20, height: 25)
        UIGraphicsBeginImageContext(size)
        pinImage.draw(in: CGRect(x: 0,y: 0,width: size.width,height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        image = resizedImage
    }


    // Detects hits on the Annotation view
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if (hitView != nil)
        {
            self.superview?.bringSubview(toFront: self)
        }
        return hitView
    }

    // Checks if point is inside this view
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
