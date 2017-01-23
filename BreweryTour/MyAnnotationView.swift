//
//  MyAnnotationView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/22/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import UIKit
import MapKit

class MyAnnotationView: MKAnnotationView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        frame.size.width = frame.size.width * 2
    }


    init(annot: MKAnnotation, reuse: String!, brewery: Brewery?) {
        super.init(annotation: annot, reuseIdentifier: reuse)
        // Format annotation callouts here

        // Set the information icon on the right button
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        annotation = annotation

        // Resize image
        let pinImage = UIImage(imageLiteralResourceName: "PinImage")
        let size = CGSize(width: 15, height: 20)
        UIGraphicsBeginImageContext(size)
        pinImage.draw(in: CGRect(x: 0,y: 0,width: size.width,height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        image = resizedImage
        if let brewery = brewery {
            setBrewery(brewery)
        }
    }


    func setBrewery(_ brewery: Brewery) -> MyAnnotationView {
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
