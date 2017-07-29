//
//  CoreDataStack.swift
//  BreweryTour
//
//  Created by James Jongsurasithiwat on 9/4/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//


/**
 This is the coredata model for the whole project
 **/
import CoreData
import SwiftyBeaver

/// A protocol that only allows for deleting all the data in Core Data and seeing the results
protocol CoreDataEntriesDeletable {

    ///
    /// This method deletes all the objects currently in coredata.
    ///
    /// - parameters:
    ///   - completion: The completion handler that will handle the results of deletion.
    ///     - success: A boolean representing whether all deletions succeeded.
    ///     - results: A struct containing which database actions completed successfully.
    func deleteAllDataAndSaveAndNotifyViews(completion: @escaping (Bool, ResultsOfCoreDataDeletion) -> () )

    ///
    /// This method gets a count of all the elements in coredata as individual properties.
    /// - returns:
    /// A struct containing the counts of all the objects currently in coredata
    /// or nil if there was problem querying for the counts
    func getCountsOfObjectsInCoreData() -> CountOfObjectsInCoreData?
}


protocol SavableCoreDataStack {

    /// This method saves the current state of CoreData to file
    /// by creating a new NSManagedObjectContext
    /// - parameters: 
    ///     - completionHandler: what ever closure want to be notified that deletion 
    ///     has completed
    ///
    func saveToFile(completionHandler: ((Bool) -> ())?)
}


/// A Structure to hold all the counts of objects currently in Core Data

internal struct CountOfObjectsInCoreData: CustomStringConvertible, Equatable {

    var beerObjectsCount: Int = 0
    var breweryObjectsCount: Int = 0
    var styleObjectsCount: Int = 0
    var description: String {
        return "Beer objects preset: \(beerObjectsCount), Brewery objects present: \(breweryObjectsCount), Style objects present: \(styleObjectsCount)"
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    /// Every property of the struct must be equal for equality
    ///
    /// - parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - returns:
    ///     true or false
    static internal func ==(lhs: CountOfObjectsInCoreData, rhs: CountOfObjectsInCoreData) -> Bool {
        return lhs.beerObjectsCount == rhs.beerObjectsCount &&
            lhs.breweryObjectsCount == rhs.breweryObjectsCount &&
            lhs.styleObjectsCount == rhs.styleObjectsCount
    }
}


/// A structure to hold all the results of the last deletion attempt on Core Data

internal struct ResultsOfCoreDataDeletion: CustomStringConvertible, Equatable {
    var beersDeletedSuccessfully: Bool = false
    var breweriesDeletedSuccessfully: Bool = false
    var stylesDeletedSuccessfully: Bool = false
    var description: String {
        return "beers deleted: \(beersDeletedSuccessfully),\n breweries deleted: \(breweriesDeletedSuccessfully),\n styles deleted: \(stylesDeletedSuccessfully)\n"
    }

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    /// - returns: 
    ///     true or false
    ///
    static internal func ==(lhs: ResultsOfCoreDataDeletion, rhs: ResultsOfCoreDataDeletion) -> Bool {
        return lhs.beersDeletedSuccessfully == rhs.beersDeletedSuccessfully &&
            lhs.breweriesDeletedSuccessfully == rhs.breweriesDeletedSuccessfully &&
            lhs.stylesDeletedSuccessfully == rhs.stylesDeletedSuccessfully
    }

}


// MARK: - CoreDataStack Definition
/// The main Core Data Stack Object

class CoreDataStack: NSObject {

    // MARK: - Constants
    private let sqlFilename : String = "com.breweries.jamesjongs.sqlite"

    // MARK: - Variables
    internal var container: NSPersistentContainer!
    private var model: NSManagedObjectModel!
    internal var mainStoreCoordinator: NSPersistentStoreCoordinator!
    private var modelURL: NSURL!
    private var dbURL: NSURL!
    internal var breweryCreationContext: NSManagedObjectContext?
    fileprivate let mediator = Mediator.sharedInstance()

    fileprivate let beerFetch: NSFetchRequest<Beer> = Beer.fetchRequest()
    fileprivate let breweryFetch: NSFetchRequest<Brewery> = Brewery.fetchRequest()
    fileprivate let styleFetch: NSFetchRequest<Style> = Style.fetchRequest()


    // MARK: - Initializers
    init?(modelName: String) {

        super.init()

        // New Swift3 code
        container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores(completionHandler: {
            (description, error) -> Void in
            if let error = error {
                SwiftyBeaver.error("Error creating NSpersistentContainer and loading a persistentStore\n\(error.localizedDescription)")
                // FIXME: Maybe add something that warns the user that the program can no longer function because the main data store could not be initialized.
            }
        })
        breweryCreationContext = container.newBackgroundContext()
    }
}


// MARK: - SavableCoreDataStack
/// Save logic that works on the local container persistent container

extension CoreDataStack: SavableCoreDataStack {

    // Saves all objects in context to disk.
    internal func saveToFile(completionHandler: ((Bool) -> ())? = nil ) {
        container.performBackgroundTask({
            (objectContext) -> Void in
            objectContext.automaticallyMergesChangesFromParent = true
            objectContext.performAndWait {
                guard objectContext.hasChanges else {
                    completionHandler?(false)
                    SwiftyBeaver.warning("This context says it have no changes to update:\(objectContext.description)")
                    return
                }
                self.saveAndHandleErrors(inContext: objectContext,
                                    withCompletion: completionHandler)
            }
        })
    }

    private func saveAndHandleErrors(inContext objectContext: NSManagedObjectContext,
                                     withCompletion completion: ((Bool) -> ())? = nil ) {
        do {
            try objectContext.save()
            completion?(true)
            // FIXME:
            print("I don't think this ever fires because it's new context and the changes are in the other context")
        } catch let error {
            completion?(false)
            SwiftyBeaver.error("Unable to save CoreData to file:\n\(error.localizedDescription)")
        }
    }

}


// MARK: - CoreDataEntriesDeletable
/// Basically all the data deletion from the settings screen.

extension CoreDataStack: CoreDataEntriesDeletable {

     /// Is a generic version of a batch delete command for all the entities in Core Data.
     /// - note: This will not save the deletions in the context.
     /// - parameters:
     ///    - entity: The NSEntityDescription name we are going to batch delete
     ///    - context: The NSManagedObjectContext on which the delete will occur.
     /// - returns:
     ///    - A boolean signifying if the deletion was a success

//    private func deleteFromCoreData(entity: String, context: NSManagedObjectContext) -> Bool {
//        let genericRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "\(entity)")
//        let genericBatchDelete = NSBatchDeleteRequest(fetchRequest: genericRequest)
//        genericBatchDelete.resultType = .resultTypeCount
//        var success: Bool?
//        context.performAndWait {
//            do {
//                _ = try context.execute(genericBatchDelete) as! NSBatchDeleteResult
//                try context.save()
//                success = true
//            } catch {
//                success = false
//            }
//        }
//        return success!
//    }

    
    internal func getCountsOfObjectsInCoreData() -> CountOfObjectsInCoreData? {
        var results = CountOfObjectsInCoreData()
        do {
            results.beerObjectsCount = try self.container.viewContext.fetch(self.beerFetch).count
            results.breweryObjectsCount = try self.container.viewContext.fetch(self.breweryFetch).count
            results.styleObjectsCount
                = try self.container.viewContext.fetch(self.styleFetch).count
        } catch let error {
            SwiftyBeaver.error("There was an error while trying to getCountOfObjectsInCoreData:\n\(error.localizedDescription)")
            return nil
        }
        return results
    }


    internal func deleteAllDataAndSaveAndNotifyViews(completion: @escaping (
        _ success: Bool,
        _ results: ResultsOfCoreDataDeletion) -> () ) {
        container?.performBackgroundTask() {

            (context) in
            // Call each successvie deletion command

            let beerDeletionSuccess = self.deleteBeerData(inContext: context)
            let breweryDeletionSuccess = self.deleteBreweryData(inContext: context)
            let styleDeletionSuccess = self.deleteStyleData(inContext: context)

            let resultsOfSaving = self.saveDeletions(inContext: context)

            // Save the results of each deletion command, return the results in the completion handler.

            // FIXME: Mediator should tell all observers to stop viewing as
            // we are making a critical update.
            // The fix involves going into mediator setting up a variable
            // to lock notifications to observer.
            // Maybe even tell observers to stop updating?
            // delete our data and then renotify our observers
            // Ideally this could have been done with KVO?

            // Tell all observers to update their state
            self.mediator.allBeersAndBreweriesDeleted()

            let deletionResults = self.buildUpReturnResults(beerSuccess: beerDeletionSuccess, brewerySuccess: breweryDeletionSuccess, styleSuccess: styleDeletionSuccess)

            completion(resultsOfSaving && beerDeletionSuccess && breweryDeletionSuccess && styleDeletionSuccess, deletionResults)
            return
        }
    }


    private func buildUpReturnResults(beerSuccess: Bool,
                                      brewerySuccess: Bool,
                                      styleSuccess: Bool) -> ResultsOfCoreDataDeletion {
        var deletionResults = ResultsOfCoreDataDeletion()
        deletionResults.beersDeletedSuccessfully = beerSuccess
        deletionResults.breweriesDeletedSuccessfully = brewerySuccess
        deletionResults.stylesDeletedSuccessfully = styleSuccess
        return deletionResults
    }


    private func deleteBeerData(inContext context: NSManagedObjectContext) -> Bool {
        let request = NSBatchDeleteRequest(fetchRequest:  self.beerFetch as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try context.execute(request)
            // FIXME: return value of Bool
            return true
        } catch let error {
            SwiftyBeaver.error("Unable to delete Beer data due to error:\n\(error.localizedDescription)")
            return false
        }
    }


    private func deleteStyleData(inContext context: NSManagedObjectContext) -> Bool {
        let request = NSBatchDeleteRequest(fetchRequest: self.styleFetch as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try context.execute(request)
            return true
        } catch let error {
            SwiftyBeaver.error("Unable to delete Style data due to error:\n\(error.localizedDescription)")
            return false
        }
    }


    private func deleteBreweryData(inContext context: NSManagedObjectContext) -> Bool {
        let request = NSBatchDeleteRequest(fetchRequest: self.breweryFetch as! NSFetchRequest<NSFetchRequestResult>)
        do {
            try context.execute(request)
            return true
        } catch let error {
            SwiftyBeaver.error("Unable to delete style data due to error:\n\(error.localizedDescription)")
            return false
        }
    }


    /// Save deletions to persistent store.
    private func saveDeletions(inContext context: NSManagedObjectContext) -> Bool {
        do {
            try context.save()
            return true
        } catch let error {
            SwiftyBeaver.error("Error saving deletions:\n\(error.localizedDescription)")
            return false
        }
    }
}



