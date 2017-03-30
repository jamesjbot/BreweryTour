//
//  AllBeersTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/12/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

/*
    This is the view model contains the extra code that give a BeersViewModel
    the ability to search for results online.
 */

import Foundation
import UIKit
import CoreData


class AllBeersViewModel: BeersViewModel, Subject {

}


// MARK: - OnlineSearchCapable

extension AllBeersViewModel: OnlineSearchCapable {
    // When the user enters the name of a beer and it is not present.
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> Void)?) {
        BreweryDBClient.sharedInstance().downloadBeersBy(name: searchTerm) {
            (success, msg) -> Void in
            guard success == true else {
                completion?(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                try self.frc.performFetch()
                super.observer?.sendNotify(from: self, withMsg: Message.Reload)
                completion?(true, "Success")
            } catch {
                completion?(false, "Failed Request")
            }
        }
    }
}
