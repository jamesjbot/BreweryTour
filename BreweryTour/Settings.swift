
//
//  Settings.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/11/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
import UIKit
import Foundation
import CoreData

class Settings: UIViewController {

    // MARK: Constants
    let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack

    // MARK: IBOutlet
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var activityIndic: UIActivityIndicatorView!
    
    @IBAction func deleteBeersBrewery(_ sender: AnyObject) {
    // Prompt user should we delete all the beers and breweries
    // Create action for prompt
        func deleteAll(_ action: UIAlertAction){
            //activityIndicator.startAnimating()
            let success = coreDataStack?.deleteBeersAndBreweries()
            activityIndic.stopAnimating()
            if success == true {
                displayAlertWindow(title: "Delete Data", msg: "Successful")
            } else {
                displayAlertWindow(title: "Delete Data", msg: "Failed to delete data, \nPlease try again.")
            }
            
        }
        activityIndic.startAnimating()
        activityIndic.isHidden = false
        let action = UIAlertAction(title: "Delete",
                                   style: .default,
                                   handler: deleteAll)
        displayAlertWindow(title: "Delete All Data",
                           msg: "Are you sure you want to delete all data, this includes tasting notes and favorites?",
                           actions: [action])
    }
}
