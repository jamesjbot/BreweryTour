//
//  AllBeersTableList.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/12/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class AllBeersViewModel: BeersViewModel, Subject {

}

extension AllBeersViewModel: OnlineSearchCapable {
    // When the user enters the name of a beer and it is not present.
    internal func searchForUserEntered(searchTerm: String, completion: ((Bool, String?) -> Void)?) {
        print("allbeers \(#line) searchForUserEntered ")
        BreweryDBClient.sharedInstance().downloadBeersBy(name: searchTerm) {
            (success, msg) -> Void in
            guard success == true else {
                completion!(success,msg)
                return
            }
            // If the query succeeded repopulate this view model and notify view to update itself.
            do {
                try self.frc.performFetch()
                super.observer?.sendNotify(from: self, withMsg: "Reload data")
                completion!(true, "Success")
            } catch {
                completion!(false, "Failed Request")
            }
        }
    }
}
