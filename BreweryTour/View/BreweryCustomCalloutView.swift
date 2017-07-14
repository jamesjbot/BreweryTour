//
//  BreweryCustomCalloutView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 5/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import UIKit

class BreweryCustomCalloutView: UIView {

    @IBOutlet weak var favoriteImage: UIImageView!
    @IBOutlet var breweryName: UILabel! {
        didSet {
            breweryName.adjustsFontSizeToFitWidth = true
        }
    }
    @IBOutlet weak var breweryWebSite: UILabel! {
        didSet {
            breweryWebSite.adjustsFontSizeToFitWidth = true
        }
    }
    
}
