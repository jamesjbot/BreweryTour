//
//  BeerDetailViewController.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/12/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class BeerDetailViewController: UIViewController {

    // MARK: IBOutlets
    
    @IBOutlet weak var breweryName: UILabel!
    
    @IBOutlet weak var beerNameLabel: UILabel!
    
    @IBOutlet weak var availableText: UILabel!
    
    @IBOutlet weak var beerDescriptionTextView: UITextView!
    
    @IBOutlet weak var favoriteButton: UIButton!

    
    @IBAction func favoriteClicked(_ sender: UIButton) {
        // Must change the state first
        isBeerFavorited = !isBeerFavorited
        var image : UIImage? = nil
        if isBeerFavorited! {
            image = UIImage(named: "heart_icon.png")
            sender.setImage(image, for: .normal)
        } else {
            image = UIImage(named: "heart_icon_black_white_line_art.png")
        }
        sender.setImage(image, for: .normal)
    }
    
    // TODO Must set favorite on initialization
    private var isBeerFavorited : Bool!
    
    internal var beer : Beer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        beerNameLabel.text = beer.beerName
        beerDescriptionTextView.text = beer.beerDescription
        if let availText = beer.availability {
            availableText.text = "Availability: \(availText)"
        }
        breweryName.text = beer.brewer?.name
        //        favoriteButton.isSelected = false
//        let heartImage = UIImage(contentsOfFile: "heart_icon.png")
//        let heartOff = UIImage(contentsOfFile: "heart_icon_black_white_line_art.png")
//        favoriteButton.setImage(heartImage, for: .selected )
//        favoriteButton.setImage(heartOff, for: .normal)
        
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
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
