//
//  OnlineSearch.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 12/31/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation

protocol OnlineSearchCapable {
    func searchForUserEntered(searchTerm: String,
                              completion: ((_ success : Bool, _ msg : String?) -> Void)?)
}
