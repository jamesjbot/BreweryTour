//
//  BeerDetailViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/*
    This program shows the details of a beer.
    You can unfavorite / favorite a beer.
    You can also add tasting notes to the beer that will be saved.
 */

import UIKit
import CoreData

class BeerDetailViewController: UIViewController {

    // MARK: - Constants

    private let container = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext


    // MARK: - Variables

    internal var beer : Beer!
    private var isBeerFavorited : Bool!


    // MARK: - IBOutlets

    @IBOutlet weak var abv: UILabel!
    @IBOutlet weak var availableText: UILabel!
    @IBOutlet weak var beerDescriptionTextView: UITextView!
    @IBOutlet weak var beerImage: UIImageView!
    @IBOutlet weak var beerNameLabel: UILabel!
    @IBOutlet weak var breweryName: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var ibu: UILabel!
    @IBOutlet weak var organicLabel: UILabel!
    @IBOutlet weak var style: UILabel!
    @IBOutlet weak fileprivate var tasting: UITextView!


    // MARK: - IBActions
    
    @IBAction func favoriteClicked(_ sender: UIButton) {
        // Must change the state first
        isBeerFavorited = !isBeerFavorited
        var image : UIImage? = nil
        if isBeerFavorited! {
            image = UIImage(named: "heart_icon.png")
            sender.setImage(image, for: .normal)
            saveBeerInCoreDataToBackgroundContext(makeFavorite: true)

        } else {
            image = UIImage(named: "heart_icon_black_white_line_art.png")
            saveBeerInCoreDataToBackgroundContext(makeFavorite: false)
        }
        sender.setImage(image, for: .normal)
    }

    
    // MARK: - Functions

    private func getStyleName(id : String,
                              completion: @escaping (_ name: String ) -> Void ) {
        let request = NSFetchRequest<Style>(entityName: "Style")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format : "id = %@", id )
        readOnlyContext?.perform {
            do {
                let result = try self.readOnlyContext?.fetch(request)
                completion(result?.first?.displayName as String? ?? "")
            } catch {
                // StyleID not in database.
                completion("")
            }
        }
    }


    // All beers are in the database already, we just mark their
    // favorite status and update tasting notes
    fileprivate func saveBeerInCoreDataToBackgroundContext(makeFavorite: Bool) {
        container?.performBackgroundTask() {
            (context) -> Void in
            let updatableBeer = context.object(with: self.beer.objectID) as! Beer
            updatableBeer.favorite = makeFavorite
            updatableBeer.tastingNotes = self.tasting.text
            do {
                try context.save()
            } catch {
                self.displayAlertWindow(title: "Saving Beer data", msg: "There was an error saving\nRetype notes or click favorite again")
            }
        }
    }


    private func searchForBeerInCoreData(context: NSManagedObjectContext) -> Beer? {
        // Check to make sure the Beer isn't already in the database
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [beer.id!])
        do {
            let results = try context.fetch(request)
            if (results.count) > 0 {
                return results[0]
            }
        } catch {
            // Should never happen.
            fatalError("Error retriving a beer")
        }
        return nil
    }
    

    // Makes the description and tasting notes UITextView scroll to the top.
    override func viewDidLayoutSubviews() {
        beerDescriptionTextView.setContentOffset(CGPoint.zero, animated: false)
        tasting.setContentOffset(CGPoint.zero, animated: false)
    }


    // MARK: - Life Cycle Management 

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Attach delegate to tasting notes so we can save on finshed editing
        tasting.delegate = self
        
        // See if this has already been favorited, if so use the favorite information
        if let BeerInThisCoreDataContext: Beer = searchForBeerInCoreData(context: readOnlyContext!) {
            beer = BeerInThisCoreDataContext
        }

        // Set the on screen properties
        beerNameLabel.text = beer.beerName
        beerNameLabel.adjustsFontSizeToFitWidth = true

        breweryName.text = "By: " + (beer.brewer?.name ?? "Not Available")
        breweryName.adjustsFontSizeToFitWidth = true

        availableText.text = "Availability: " + (beer.availability ?? "Not Provided")
        availableText.adjustsFontSizeToFitWidth = true
        
        // Populate beer image if it is in the database
        if let data : NSData = (beer.image) {
            let im = UIImage(data: data as Data)
            beerImage.image = im
        }

        // Populate Beer description
        beerDescriptionTextView.text = "Description: " + (beer.beerDescription ?? "None Provided")

        // Populate Tasting notes
        tasting.text = beer.tastingNotes ?? "Your tasting notes"

        // Change this to beer's favorite status
        let favoriteIcon : UIImage?
        if beer.favorite {
            isBeerFavorited = true
            favoriteIcon = UIImage(named: "heart_icon.png")
        } else {
            isBeerFavorited = false
            favoriteIcon = UIImage(named: "heart_icon_black_white_line_art.png")
        }
        favoriteButton.setImage(favoriteIcon, for: .normal)
        organicLabel.text = "Organic: " + (beer.isOrganic == true ? "Yes" : "No")
        abv.text = "ABV: " + (beer.abv ?? "")
        ibu.text = "IBU: " + (beer.ibu ?? "")
        getStyleName(id: beer.styleID!){
            (name) -> Void in
            self.style.text = "Style: " + name
        }
        // Raise keyboard when typing in UITextView
        subscribeToKeyboardShowNotifications()
    }
}


// MARK: - UITextViewDelegate

extension BeerDetailViewController : UITextViewDelegate {

    // Every time the user finshes editing their tasting notes save the notes
    func textViewDidEndEditing(_ textView: UITextView) {
        saveBeerInCoreDataToBackgroundContext(makeFavorite: beer.favorite)
    }


    // This clears the textView when the user begins editting the text view
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        //The tasting notes should only be deleted if it is placeholder info
        if textView.text == "Your tasting notes" {
            textView.text = ""
        }
        return true
    }

    
    // Apply textchanges or remove keyboard.
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // When the done key is pressed don't change text.
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }
}



