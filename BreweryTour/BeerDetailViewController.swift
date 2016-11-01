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

class BeerDetailViewController: UIViewController, UITextViewDelegate{

    
    // TODO Remove this test code
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
    
            let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Beer")
            let batch = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> )
            do {
                try persistentContext?.execute(batch)
                //try coreDataStack?.mainStoreCoordinator.execute(batch, with: (favoriteContext)!)
                print("Batch Deleted completed")
            } catch {
                fatalError("batchdelete failed")
            }
    }
    
    // MARK: IBOutlets
    
    @IBOutlet weak var tasting: UITextView!
    
    @IBOutlet weak var breweryName: UILabel!
    
    @IBOutlet weak var beerNameLabel: UILabel!
    
    @IBOutlet weak var availableText: UILabel!
    
    @IBOutlet weak var abv: UILabel!
    
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
            saveToBeerInCoreData(makeFavorite: true)
        } else {
            image = UIImage(named: "heart_icon_black_white_line_art.png")
            saveToBeerInCoreData(makeFavorite: false)
        }
        sender.setImage(image, for: .normal)
    }
    
    // MARK: Variables
    
    private var isBeerFavorited : Bool!
    
    internal var beer : Beer!
    
    private let persistentContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.persistingContext
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Attach delegate to tasting notes in viewcontroller
        tasting.delegate = self
        
        // See if this has already been favorited, if so use the favorite information
        if let BeerInThisCoreDataContext : Beer = searchForBeerInCoreData() {
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
        
        abv.text = "ABV:" + beer.abv!
        ibu.text = "IBU:" + beer.ibu!
    }

    
    private func searchForBeerInCoreData() -> Beer? {
        // Check to make sure the Beer isn't already in the database
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [beer.id!])
        do {
            let results = try persistentContext?.fetch(request)
            if (results?.count)! > 0 {
                return results?[0]
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
    private func saveToBeerInCoreData(makeFavorite: Bool) {
        // TODO there is an error saveing
        do {
            beer.favorite = makeFavorite
            beer.tastingNotes = tasting.text
            try persistentContext?.save()
        } catch {
            fatalError("Error adding/saving a beer")
        }
    }
    
    
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
        saveToBeerInCoreData(makeFavorite: beer.favorite)
    }
}



