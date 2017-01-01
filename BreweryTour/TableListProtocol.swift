//
//  TableListProtocol.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 10/19/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the interface file for all view models that back up a table.
 **/

import Foundation
import CoreData
import UIKit

protocol TableList {
    func getNumberOfRowsInSection(searchText : String?) -> Int
    func filterContentForSearchText(searchText: String) -> Void// [NSManagedObject]
    func cellForRowAt(indexPath : IndexPath,
                      cell : UITableViewCell,
                      searchText : String?) -> UITableViewCell
    func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) -> AnyObject?
}
