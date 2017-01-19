//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by James Jongsurasithiwat on 9/4/16.
//  Copyright © 2016 James Jongs. All rights reserved.
//
/** This is the coredata model for the whole project
 **/

import CoreData

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
    //internal var persistingContext: NSManagedObjectContext!
    //public var backgroundContext : NSManagedObjectContext!
    //internal var mainContext: NSManagedObjectContext!
    
    // MARK: - Initializers
    init?(modelName: String) {
        super.init()
        
        // New Swift3 code
        container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores(completionHandler: {
            (descrip, err) -> Void in
            if let error = err {
                fatalError(error.localizedDescription)
            }
        })
        breweryCreationContext = container.newBackgroundContext()
    }
}


extension CoreDataStack {

    // This function delete all the entities from core data.
    private func deleteFromCoreData(entity: String, context: NSManagedObjectContext) -> Bool {
        let genericRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "\(entity)")
        let genericBatchDelete = NSBatchDeleteRequest(fetchRequest: genericRequest)
        genericBatchDelete.resultType = .resultTypeCount
        var success: Bool?
        context.performAndWait {
            do {
                _ = try context.execute(genericBatchDelete) as! NSBatchDeleteResult
                try context.save()
                success = true
            } catch {
                success = false
            }
        }
        return success!
    }
    
    
    public func saveToFile() {
        // Saves all the way to disk.
        container.performBackgroundTask({
            (objectContext) -> Void in
            objectContext.automaticallyMergesChangesFromParent = true
            objectContext.performAndWait {
                if objectContext.hasChanges {
                    do {
                        try objectContext.save()
                    } catch let error {
                        fatalError("Unable to save due to error:\n\(error)")
                    }
                }
            }
        })
    }
   
}



