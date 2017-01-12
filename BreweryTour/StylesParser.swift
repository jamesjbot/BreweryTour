//
//  StylesParser.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 1/11/17.
//  Copyright © 2017 James Jongs. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class StylesParser: ParserProtocol {

    // MARK: - Constants

    private let readOnlyContext = ((UIApplication.shared.delegate) as! AppDelegate).coreDataStack?.container.viewContext

    // MARK: - Functions

    func parse(response : NSDictionary,
               querySpecificID : String?,
               completion: (( (_ success :  Bool, _ msg: String?) -> Void )?) ) {

        // Saves the multiple styles from the server
        guard let styleArrayOfDict = response["data"] as? [[String:AnyObject]] else { // We must have data to process else escape
            completion!(false, "No styles data" )
            return
        }

        // Check to see if the style is already in coredata then skip, else add
        let request = NSFetchRequest<Style>(entityName: "Style")
        request.sortDescriptors = []

        readOnlyContext?.perform {

            // Creating these in the readOnlyContext because they
            // are critically needed in the UI

            for aStyle in styleArrayOfDict {
                let localId = aStyle["id"]?.stringValue

                do { // Find existing style then skip.
                    request.predicate = NSPredicate(format: "id = %@", localId!)
                    let results = try self.readOnlyContext?.fetch(request)

                    // if the style is already in coredata skip it
                    guard (results?.count)! == 0 else {
                        continue
                    }

                } catch {
                    completion!(false, "Failed Reading Styles from database")
                    return
                }

                let localName = aStyle["name"]

                // Creates a new style
                _ = Style(id: localId!,
                          name: localName! as! String,
                          context: self.readOnlyContext!)
                do {
                    try self.readOnlyContext?.save()
                } catch _ {
                    fatalError("Fatal Error Writing to CoreData")
                }
            }
            completion!(true,"Completed processing styles")
            return
        }

    }
}
