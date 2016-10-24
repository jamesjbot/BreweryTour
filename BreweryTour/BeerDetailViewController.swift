//
//  BeerDetailViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class BeerDetailViewController: UIViewController, UITextViewDelegate{

    // MARK: IBOutlets
    
    // TODO Remove this test code
    @IBAction func deleteAll(_ sender: UIBarButtonItem) {
    
            let request : NSFetchRequest<Style> = NSFetchRequest(entityName: "Beer")
            let batch = NSBatchDeleteRequest(fetchRequest: request as! NSFetchRequest<NSFetchRequestResult> )
            do {
                try favoriteContext?.execute(batch)
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
            saveToFavoritesInCoreData(makeFavorite: true)
        } else {
            image = UIImage(named: "heart_icon_black_white_line_art.png")
            saveToFavoritesInCoreData(makeFavorite: false)
        }
        sender.setImage(image, for: .normal)
    }
    
    // MARK: Variables
    
    // TODO Must set favorite on initialization
    private var isBeerFavorited : Bool!
    
    internal var beer : Beer!
    
    private let favoriteContext = (UIApplication.shared.delegate as! AppDelegate).coreDataStack?.favoritesContext
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Attach delegate to viewcontroller
        tasting.delegate = self
        
        // See if this has already been favorited, if so use the favorite information
        if let beerFavoriteInformation : Beer = searchForBeerInFavorites() {
            beer = beerFavoriteInformation
        }
        
        // Set the on screen properties
        beerNameLabel.text = beer.beerName
        breweryName.text = beer.brewer?.name
        if let availText = beer.availability {
            availableText.text = "Availability: \(availText)"
        }
        // TODO add IBU and ABV data to beer
        if let data : NSData = (beer.image) {
            let im = UIImage(data: data as Data)
            beerImage.image = im
        }
        beerDescriptionTextView.text = beer.beerDescription
        if let tastingNotes = beer.tastingNotes {
            tasting.text = tastingNotes
        }
        
        
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
    }

    
    private func searchForBeerInFavorites() -> Beer? {
        // Check to make sure the Beer isn't already in the database
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [beer.id!])
        do {
            let results = try favoriteContext?.fetch(request)
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
    private func saveToFavoritesInCoreData(makeFavorite: Bool) {
        do {
            beer.favorite = makeFavorite
            beer.tastingNotes = tasting.text
            try favoriteContext?.save()
        } catch {
            fatalError("Error adding/saving a beer")
        }
        
    }
    
    
//    private func deleteFromFavoritesInCoreData() {
//        print("attempting to delete")
//        // Check to make sure the Beer isn't already deleted in the database
//        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
//        request.sortDescriptors = []
//        print("beerid:\(beer.id)")
//        request.predicate = NSPredicate(format: "id == %@", argumentArray: [beer.id!])
//        do {
//            let results = try favoriteContext?.fetch(request)
//            if (results?.count)! > 0 {
//                favoriteContext?.delete((results?[0])!)
//                try favoriteContext?.save()
//                print("Deleted")
//            }
//        } catch {
//            fatalError("Error deleting a beer")
//        }
//
//    }
    
    
    // This clears the textView when the user begins editting the text view
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        // TODO Delete test code
        print("UITextView textViewShouldBeginEditing called")
        textView.text = ""
        return true
    }
    
    
    func textViewDidEndEditing(_ textView: UITextView) {
        saveToFavoritesInCoreData(makeFavorite: true)
    }
}



