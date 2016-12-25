
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
    let container = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.container
    let beerFetch: NSFetchRequest<Beer> = Beer.fetchRequest()
    let breweryFetch: NSFetchRequest<Brewery> = Brewery.fetchRequest()
    let styleFetch: NSFetchRequest<Style> = Style.fetchRequest()

    // MARK: IBOutlet
    @IBOutlet weak var automaticMapSwitch: UISwitch!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var activityIndic: UIActivityIndicatorView!
    
    @IBAction func toggleAutomaticMap(_ sender: UISwitch) {
    }
    
    @IBAction func deleteBeersBrewery(_ sender: AnyObject) {
        // Prompt user should we delete all the beers and breweries
        // Create action for prompt

        func deleteAll(_ action: UIAlertAction) {
            self.startIndicator()
            container?.performBackgroundTask({ (context) in
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
                self.stopIndicator()
                do {
                    try context.save()
                } catch let error {
                    success = false
                    self.displayAlertWindow(title: "Error", msg: "Successfully deleted but unable to save?")
                }
                if success == true {
                    self.displayAlertWindow(title: "Delete Data", msg: "Successful"+self.statistics())
                }
            })
        }
        let action = UIAlertAction(title: "Delete",
                                   style: .default,
                                   handler: deleteAll)
        displayAlertWindow(title: "Delete All Data",
                           msg: "Are you sure you want to delete all data, this includes\ntasting notes and favorites?"+statistics(),
                           actions: [action])
        //activityIndic.isHidden = false
    }
    
    
    // MARK: - Functions
    
    func statistics() -> String {
        do {
            let beerCount =  try container?.viewContext.fetch(beerFetch).count
            let styleCount = try container?.viewContext.fetch(styleFetch).count
            let breweryCount = try container?.viewContext.fetch(breweryFetch).count
            return "\nStyles:\(styleCount!)\nBeers\(beerCount!)\nBreweries:\(breweryCount!)"
        } catch let error {
            self.displayAlertWindow(title: "Error", msg: "Please try again.")
            return ""
        }
    }
    
    
    func startIndicator() {
        DispatchQueue.main.async {
            self.activityIndic.startAnimating()
            self.activityIndic.setNeedsDisplay()
        }
    }
    
    
    func stopIndicator() {
        DispatchQueue.main.async {
            self.activityIndic.stopAnimating()
            self.activityIndic.isHidden = true
            self.activityIndic.setNeedsDisplay()
        }
    }
}
