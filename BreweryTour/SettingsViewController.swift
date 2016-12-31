
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
 */
import UIKit
import Foundation
import CoreData

class Settings: UIViewController {
    
    // MARK: Constants

    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    private let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    private let beerFetch: NSFetchRequest<Beer> = Beer.fetchRequest()
    private let breweryFetch: NSFetchRequest<Brewery> = Brewery.fetchRequest()
    private let styleFetch: NSFetchRequest<Style> = Style.fetchRequest()
    private let mediator = Mediator.sharedInstance()


    // MARK: IBOutlet

    @IBOutlet weak var automaticMapSwitch: UISwitch!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var activityIndic: UIActivityIndicatorView!


    // MARK: IBAction
    
    @IBAction func downloadAllBreweries(_ sender: UIButton) {

        func downloadAll(_ action: UIAlertAction) {
            displayAlertWindow(title: "Downloading...",
                               msg: "You got it, go take break this will take awhile")
            BreweryDBClient.sharedInstance().downloadAllBreweries {
                (success, msg) in
                // Use would have long move off this screen.
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
    
    @IBAction func deleteBeersBrewery(_ sender: AnyObject) {
        // Prompt user should we delete all the beers and breweries
        // Create action for prompt

        func deleteAll(_ action: UIAlertAction) {
            self.startIndicator()
            container?.performBackgroundTask({
                (context) in
                var success: Bool = true
                var request = NSBatchDeleteRequest(fetchRequest: self.beerFetch as! NSFetchRequest<NSFetchRequestResult>)
                do {
                    try context.execute(request)
                } catch let error {
                    self.displayAlertWindow(title: "Error", msg: "Error deleting Beer data \(error)")
                    success = false
                }
                request = NSBatchDeleteRequest(fetchRequest: self.styleFetch as! NSFetchRequest<NSFetchRequestResult>)
                do {
                    try context.execute(request)
                } catch let error {
                    self.displayAlertWindow(title: "Error", msg: "Error deleting Style data \(error)")
                    success = false
                }
                request = NSBatchDeleteRequest(fetchRequest: self.breweryFetch as! NSFetchRequest<NSFetchRequestResult>)
                do {
                    try context.execute(request)
                } catch let error {
                    self.displayAlertWindow(title: "Error", msg: "Error deleting Brewery data \(error)")
                    success = false
                }
                do {
                    try context.save()
                } catch _ {
                    success = false
                    self.displayAlertWindow(title: "Error", msg: "Successfully deleted but unable to save?")
                }
                self.stopIndicator()
                if success == true {
                    self.displayAlertWindow(title: "Delete Data", msg: "Successful"+self.statistics())
                }
                self.mediator.allBeersAndBreweriesDeleted()
            })
        }
        let action = UIAlertAction(title: "Delete",
                                   style: .default,
                                   handler: deleteAll)
        displayAlertWindow(title: "Delete All Data",
                           msg: "Are you sure you want to delete all data, this includes\ntasting notes and favorites?"+statistics(),
                           actions: [action])
    }
    
    
    // MARK: - Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        Mediator.sharedInstance().setAutomaticallySegue(to: automaticMapSwitch.isOn)
    }

    private func statistics() -> String {
        do {
            let beerCount =  try container?.viewContext.fetch(beerFetch).count
            let styleCount = try container?.viewContext.fetch(styleFetch).count
            let breweryCount = try container?.viewContext.fetch(breweryFetch).count
            return "\nStyles:\(styleCount!)\nBeers\(beerCount!)\nBreweries:\(breweryCount!)"
        } catch _ {
            self.displayAlertWindow(title: "Error", msg: "Please try again.")
            return ""
        }
    }
    
    
    private func startIndicator() {
        DispatchQueue.main.async {
            self.activityIndic.startAnimating()
            self.activityIndic.setNeedsDisplay()
        }
    }
    
    
    private func stopIndicator() {
        DispatchQueue.main.async {
            self.activityIndic.stopAnimating()
            self.activityIndic.isHidden = true
            self.activityIndic.setNeedsDisplay()
        }
    }
}
