//
//  FavoriteButton.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/17/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import UIKit

class FavoriteButton: UIButton {

    private let cd = UIApplication.shared.delegate
    
    internal var isFavorite : Bool {
        get {
            return isFavorite
        }
        set {
            isFavorite = newValue
            if isFavorite {
                self.setImage(UIImage(named: "heart_icon.png"), for: .normal)
            } else {
                self.setImage(UIImage(named: "heart_icon_black_white_line_art.png"), for: .normal)
            }        
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    

}
