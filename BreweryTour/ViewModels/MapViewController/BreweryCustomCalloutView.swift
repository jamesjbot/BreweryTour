//
//  BreweryCustomCalloutView.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 5/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import UIKit
import CoreData

@IBDesignable
class BreweryCustomCalloutView: UIView {

    var backgroundNSManagedObject: NSManagedObject?
    var tabBarController: UITabBarController?

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
    @IBAction func viewBeersAction(_ sender: UIButton) {
        let broadcaster = Mediator.sharedInstance() as MediatorBroadcastSetSelected
        broadcaster.select(thisItem: backgroundNSManagedObject, state: nil, completion:{(success,error)in})
            DispatchQueue.main.async {
                self.tabBarController?.selectedIndex = TabbarConstants.selectedBeersTab.rawValue
            }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
