//
//  FavoriteUIButton.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 5/1/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import UIKit
import CoreData

class FavoriteUIButton: UIButton {
    var brewery: Brewery?
    var favoriteImageView: UIImageView?
    var objectID: NSManagedObjectID?
}
