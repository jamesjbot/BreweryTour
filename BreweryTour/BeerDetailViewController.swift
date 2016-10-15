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
    
    // MARK: Variables
    
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
        let image : UIImage?
        // Change this to beer's favorite status
        if beer.favorite {
            isBeerFavorited = true
            image = UIImage(named: "heart_icon.png")
        } else {
            isBeerFavorited = false
            image = UIImage(named: "heart_icon_black_white_line_art.png")
        }
        favoriteButton.setImage(image, for: .normal)
        deleteFromCoreData()
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }
    
    
    private func saveToCoreData() {
        
        // Check to make sure the Beer isn't already in the database
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "id = %@", argumentArray: [beer.id!])
        do {
            let results = try coreDataStack?.persistingContext.fetch(request)
            if (results?.count)! == 0 {
                let b = Beer(id: beer.id!, name: beer.beerName!, beerDescription: beer.beerDescription!, availability: beer.availability!, context: (coreDataStack?.persistingContext)!)
                b.favorite = true
                try coreDataStack?.persistingContext.save()
            }
        } catch {
            fatalError("Error adding a beer")
        }
        
    }
    
    
    private func deleteFromCoreData() {
        print("attempting to delete")
        // Check to make sure the Beer isn't already deleted in the database
        let request : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
        request.sortDescriptors = []
        print("beerid:\(beer.id)")
        request.predicate = NSPredicate(format: "id == %@", argumentArray: [beer.id!])
        do {
            let results = try coreDataStack?.persistingContext.fetch(request)
            //print("results:\(results)")
            if (results?.count)! > 0 {
                coreDataStack?.persistingContext.delete((results?[0])!)
                try coreDataStack?.persistingContext.save()
                print("Deleted")
            }
        } catch {
            fatalError("Error deleting a beer")
        }
        do {
            request.predicate = nil
            let results = try coreDataStack?.persistingContext.fetch(request)
            for i in results! as [Beer]{
                print(i.id)
            }
        } catch {
            
        }
    }

}
