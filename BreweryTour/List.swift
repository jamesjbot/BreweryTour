//
//  List.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol List {
    var data : [NSManagedObject] {get set}
    func getNumberOfRowsInSection(searchText : String?) -> Int
    func filterContentForSearchText(searchText: String) -> [NSManagedObject]
    func cellForRowAt(indexPath : NSIndexPath, cell : UITableViewCell, searchText : String?) -> UITableViewCell
}
