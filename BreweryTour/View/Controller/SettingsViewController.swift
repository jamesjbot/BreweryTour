
//
//  Settings.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/11/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
    This screen allows us to delete the Styles, Beers and Breweries currently
    on the device.
    Download all the breweries in one shot.
    And disable or enable auto map segueing on choices from the CategoryScreen

 */

import UIKit
import Foundation
import CoreData
import SwiftyBeaver

class SettingsViewController: UIViewController, AlertWindowDisplaying {
    
    // MARK: - Constants

    private let coreDataStack: CoreDataEntriesDeletable? = ((UIApplication.shared.delegate as? AppDelegate)?.coreDataStack)
    private let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
//    private let mediator = Mediator.sharedInstance()
//    private let beerFetch: NSFetchRequest<Beer> = Beer.fetchRequest()
//    private let breweryFetch: NSFetchRequest<Brewery> = Brewery.fetchRequest()
//    private let styleFetch: NSFetchRequest<Style> = Style.fetchRequest()


    // MARK: - IBOutlet

    @IBOutlet weak var activityIndic: UIActivityIndicatorView!
    @IBOutlet weak var automaticMapSwitch: UISwitch!
    @IBOutlet weak var deleteButton: UIButton!


    // MARK: - IBAction


    @IBAction func deleteBeersBrewery(_ sender: AnyObject) {
        // Prompt user should we delete all the beers and breweries

        // The function that we should run if user wants to deleteAllEntries
        func deleteAllEntries(_ action: UIAlertAction) {

            self.startIndicator()

            coreDataStack?.deleteAllDataAndSaveAndNotifyViews() {
                (successfullyDeletedAllEntries: Bool,
                results: ResultsOfCoreDataDeletion) in
                self.stopIndicator()
                if successfullyDeletedAllEntries {
                    let counts: CountOfObjectsInCoreData = (self.coreDataStack?.getCountsOfObjectsInCoreData())!
                    self.displayAlertWindow(title: "Delete All Data", msg: "Successful"+self.formatStatistics(styleCount: counts.styleObjectsCount,
                                                                                                              beerCount: counts.beerObjectsCount,
                                                                                                    breweryCount: counts.breweryObjectsCount))
                } else {
                    self.displayAlertWindow(title: "Delete All Data", msg: "There was an error deleting \(results.description), try again later")
                    SwiftyBeaver.error("Notified user of error deleting entires")
                }
            }
        }

        // Create action for prompt
        let action = UIAlertAction(title: "Delete",
                                   style: .default,
                                   handler: deleteAllEntries)
        displayAlertWindow(title: "Delete All Data",
                           msg: "Are you sure you want to delete all data, this includes\ntasting notes and favorites?",//+statistics(),
                           actions: [action])
    }


    @IBAction func downloadAllBreweries(_ sender: UIButton) {

        func downloadAll(_ action: UIAlertAction) {
            displayAlertWindow(title: "Downloading...",
                               msg: "You got it, go take break this will take awhile")
            BreweryDBClient.sharedInstance().downloadAllBreweries {
                (success, msg) in
            }
        }
        let action = UIAlertAction(title: "Take as long as you want",
                                   style: .default,
                                   handler: downloadAll)
        displayAlertWindow(title: "Download All Breweries",
                           msg: "Are you sure you want to download all breweries, this will take along time to complete",
                           actions: [action])
    }


    @IBAction func toggleAutomaticMap(_ sender: UISwitch) {
        Mediator.sharedInstance().setAutomaticallySegue(to: sender.isOn)
    }


    // MARK: - Functions

    private func startIndicator() {
        DispatchQueue.main.async {
            self.activityIndic.startAnimating()
            self.activityIndic.setNeedsDisplay()
        }
    }


    private func formatStatistics(styleCount: Int, beerCount: Int, breweryCount: Int) -> String {
        return "\nStyles:\(styleCount)\nBeers\(beerCount)\nBreweries:\(breweryCount)"
    }

    private func stopIndicator() {
        DispatchQueue.main.async {
            self.activityIndic.stopAnimating()
            self.activityIndic.isHidden = true
            self.activityIndic.setNeedsDisplay()
        }
    }

    // MARK: - Life Cycle Management

    override func viewDidLoad() {
        super.viewDidLoad()
        automaticMapSwitch.isOn = Mediator.sharedInstance().isAutomaticallySegueing()
    }

}



