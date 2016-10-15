//
//  BeerDetailViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class BeerDetailViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet weak var breweryName: UILabel!
    
    @IBOutlet weak var beerNameLabel: UILabel!
    
    @IBOutlet weak var availableText: UILabel!
    
    @IBOutlet weak var abv: UILabel!
    
    @IBOutlet weak var beerDescriptionTextView: UITextView!
    
    @IBOutlet weak var favoriteButton: UIButton!

    
    @IBAction func favoriteClicked(_ sender: UIButton) {
        // Must change the state first
        isBeerFavorited = !isBeerFavorited
        var image : UIImage? = nil
        if isBeerFavorited! {
            image = UIImage(named: "heart_icon.png")
            sender.setImage(image, for: .normal)
            saveToCoreData()
        } else {
            image = UIImage(named: "heart_icon_black_white_line_art.png")
            deleteFromCoreData()
        }
        sender.setImage(image, for: .normal)
    }
    
    // TODO Must set favorite on initialization
    private var isBeerFavorited : Bool!
    
    internal var beer : Beer!
    
    private let coreDataStack = (UIApplication.shared.delegate as! AppDelegate).coreDataStack
    
    // MARK: Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        beerNameLabel.text = beer.beerName
        beerDescriptionTextView.text = beer.beerDescription
        if let availText = beer.availability {
            availableText.text = "Availability: \(availText)"
        }
        breweryName.text = beer.brewer?.name
        
        // TODO Change this to beer's favorite status
        isBeerFavorited = false
        let image = UIImage(named: "heart_icon_black_white_line_art.png")
        favoriteButton.setImage(image, for: .normal)
        
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }
    
    
    private func saveToCoreData() {
        // TODO check to make sure it isn't already in the database
        let beerNotInDB : Bool = false
        if beerNotInDB {
            Beer(id: beer.id!, name: beer.beerName!, beerDescription: beer.beerDescription!, availability: beer.availability!, context: (coreDataStack?.persistingContext)!)
            do {
                try coreDataStack?.persistingContext.save()
            } catch {
                fatalError("Error saving favorite")
            }
        }
        
    }
    
    
    private func deleteFromCoreData() {
        let beerNotInDB : Bool = false
        if beerNotInDB {
            return
        } else {
            // Get beer id delete in persistent
            // Save persistent
        }
    }

}
