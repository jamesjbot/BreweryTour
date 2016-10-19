//
//  TableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
import Foundation
import CoreData
import UIKit

protocol TableList {
    //var data : [NSManagedObject] {get set}
    //var filteredObjects : [NSManagedObject] { get set }
    func getNumberOfRowsInSection(searchText : String?) -> Int
    func filterContentForSearchText(searchText: String) -> [NSManagedObject]
    func cellForRowAt(indexPath : IndexPath, cell : UITableViewCell, searchText : String?) -> UITableViewCell
}
