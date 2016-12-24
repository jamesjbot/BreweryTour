//
//  BeerDetailViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This program shows the details of a beer.
    You can unfavorite / favorite a beer.
    You can also add tasting notes to the beer that will be saved.
 **/
import UIKit
import CoreData

class BeerDetailViewController: UIViewController {
    
    // MARK: IBOutlets
    
    @IBOutlet weak fileprivate var tasting: UITextView!
    
    @IBOutlet weak var breweryName: UILabel!
    
    @IBOutlet weak var beerNameLabel: UILabel!
    
    @IBOutlet weak var availableText: UILabel!
    
    @IBOutlet weak var organicLabel: UILabel!
    
    @IBOutlet weak var abv: UILabel!
    
    @IBOutlet weak var style: UILabel!
    
    @IBOutlet weak var ibu: UILabel!
    
    @IBOutlet weak var beerDescriptionTextView: UITextView!
    
    @IBOutlet weak var favoriteButton: UIButton!

    @IBOutlet weak var beerImage: UIImageView!
    
    // MARK: IBActions
    
    @IBAction func favoriteClicked(_ sender: UIButton) {
        // Must change the state first
        isBeerFavorited = !isBeerFavorited
        var image : UIImage? = nil
        if isBeerFavorited! {
            image = UIImage(named: "heart_icon.png")
            sender.setImage(image, for: .normal)
            saveToBeerInCoreDataToBackgroundContext(makeFavorite: true)
        } else {
            image = UIImage(named: "heart_icon_black_white_line_art.png")
            saveToBeerInCoreDataToBackgroundContext(makeFavorite: false)
        }
        sender.setImage(image, for: .normal)
    }
    
    // MARK: Variables
    
    private var isBeerFavorited : Bool!
    
    internal var beer : Beer!
    // TODO Temporary remove to use coreDataStack function to save persistent
    // rather than addressing it directly
    //private let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext
    private let container = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Attach delegate to tasting notes in viewcontroller
        tasting.delegate = self
        
        // See if this has already been favorited, if so use the favorite information
        if let BeerInThisCoreDataContext: Beer = searchForBeerInCoreData(context: readOnlyContext!) {
            beer = BeerInThisCoreDataContext
        }
        
        // Set the on screen properties
        beerNameLabel.text = beer.beerName
        breweryName.text = beer.brewer?.name
        availableText.text = "Availability: " + beer.availability!
        
        // Populate beer image if it is in the database
        if let data : NSData = (beer.image) {
            let im = UIImage(data: data as Data)
            beerImage.image = im
        }
        beerDescriptionTextView.text = beer.beerDescription
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
        style.text = "Style: " + getStyleName(id: beer.styleID!)
        organicLabel.text = "Organic: " + (beer.isOrganic == true ? "Yes" : "No")
        abv.text = "ABV: " + (beer.abv ?? "")
        ibu.text = "IBU: " + (beer.ibu ?? "")
        
        // Raise keyboard when typing in UITextView
        subscribeToKeyboardShowNotifications()
    }

    
    private func getStyleName(id : String) -> String {
        let request = NSFetchRequest<Style>(entityName: "Style")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format : "id = %@", id )
        // TODO does this need to be in a container.performBackgroundTask
        do {
            // TODO Remove 2nd persistingContext because I'm trying to test.
            // Where should you get style data.
            let result = try readOnlyContext?.fetch(request)
            return result![0].displayName!
        } catch {
            // StyleID not in database.
            return ""
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
            fatalError("Error adding a beer")
        }
        return nil
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // All beers are in the database we just mark their favorite status and tasting notes
    fileprivate func saveToBeerInCoreDataToBackgroundContext(makeFavorite: Bool) {
        container?.performBackgroundTask() {
            (context) -> Void in
            let updatableBeer = context.object(with: self.beer.objectID) as! Beer
            updatableBeer.favorite = makeFavorite
            updatableBeer.tastingNotes = self.tasting.text
            do {
                try context.save()
            } catch let error {
                print("Error saving \(error)")
                self.displayAlertWindow(title: "Saving Beer data", msg: "There was an error saving\nRetype notes or click favorite again")
            }
        }
    }
}


extension BeerDetailViewController : UITextViewDelegate {

    
    // This clears the textView when the user begins editting the text view
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        //The tasting notes should only be deleted if it is placeholder info
        if textView.text == "Your tasting notes" {
            textView.text = ""
        }
        return true
    }

    
    // Every time the user finshes editing their tasting notes save the notes
    func textViewDidEndEditing(_ textView: UITextView) {
        saveToBeerInCoreDataToBackgroundContext(makeFavorite: beer.favorite)
    }

    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        } else {
            return true
        }
    }

}



