
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
    // MARK: IBOutlet
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var activityIndic: UIActivityIndicatorView!
    
    @IBAction func deleteBeersBrewery(_ sender: AnyObject) {
        // Prompt user should we delete all the beers and breweries
        // Create action for prompt

        func deleteAll(_ action: UIAlertAction) {
            self.startIndicator()
            container?.performBackgroundTask({ (context) in
                var success: Bool = true
                let beerFetch: NSFetchRequest<Beer> = Beer.fetchRequest()
                var request = NSBatchDeleteRequest(fetchRequest: beerFetch as! NSFetchRequest<NSFetchRequestResult>)
                do {
                    try context.execute(request)
                } catch let error {
                    self.displayAlertWindow(title: "Error", msg: "Error deleting Beer data \(error)")
                    success = false
                }
                let styleFetch: NSFetchRequest<Style> = Style.fetchRequest()
                request = NSBatchDeleteRequest(fetchRequest: styleFetch as! NSFetchRequest<NSFetchRequestResult>)
                do {
                    try context.execute(request)
                } catch let error {
                    self.displayAlertWindow(title: "Error", msg: "Error deleting Style data \(error)")
                    success = false
                }
                let breweryFetch: NSFetchRequest<Brewery> = Brewery.fetchRequest()
                request = NSBatchDeleteRequest(fetchRequest: breweryFetch as! NSFetchRequest<NSFetchRequestResult>)
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
                    self.displayAlertWindow(title: "Error", msg: "Successfully deleted but unable to save?")
                }
                do {
                    let beerCount =  try context.fetch(beerFetch).count
                    let styleCount = try context.fetch(styleFetch).count
                    let breweryCount = try context.fetch(breweryFetch).count
                    if success == true {
                        self.displayAlertWindow(title: "Delete Data", msg: "Successful\nStyles:\(styleCount)\nBeers\(beerCount)\nBreweries:\(breweryCount)")
                    }
                } catch let error {
                    self.displayAlertWindow(title: "Error", msg: "Please try again.")
                }
                

            })
        }
        let action = UIAlertAction(title: "Delete",
                                   style: .default,
                                   handler: deleteAll)
        displayAlertWindow(title: "Delete All Data",
                           msg: "Are you sure you want to delete all data, this includes tasting notes and favorites?",
                           actions: [action])
        //activityIndic.isHidden = false
    }
    
    
    // MARK: - Functions
    
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
