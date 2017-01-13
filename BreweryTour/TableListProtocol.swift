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
    func cellForRowAt(indexPath : IndexPath,
                      cell : UITableViewCell,
                      searchText : String?) -> UITableViewCell
    func getNumberOfRowsInSection(searchText : String?) -> Int
    func filterContentForSearchText(searchText: String, completion: ( (_ ok: Bool) -> Void )?) -> Void
    func registerObserver(view: Observer)
    func selected(elementAt: IndexPath,
                  searchText: String,
                  completion: @escaping (_ success: Bool, _ msg: String?) -> Void ) -> AnyObject?
}
