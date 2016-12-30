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
//        
//        
//        // This resource is the same name as your xcdatamodeld contained in your project.
//        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
//            fatalError("Error loading model from bundle")
//        }
//        
//        // Save the modelURL
//        self.modelURL = modelURL as NSURL!
//        
//        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
//        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
//            fatalError("Error initializing mom from: \(modelURL)")
//        }
//        
//        // Save the managedObjectModel
//        self.model = mom
//        
//        // Create the persistent store coordinator
//        mainStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
//        
//        // Create the persisting context
//        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        
//        // Assign coordinator to persisting context
//        persistingContext.persistentStoreCoordinator = mainStoreCoordinator
//        persistingContext.name = "PersistingContext"
//        // Create Managed Ojbect Context running on the MainQueue
//        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
//        
//        // Set persistingContext as parent.
//        mainContext.parent = persistingContext
//        mainContext.name = "MainContext"
//        
//        // Load a background context
//        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
//        backgroundContext.parent = mainContext
//        backgroundContext.name = "BackgroundContext"
//        // Add an SQL lite store in the documents folder
//        // Create the SQL Store in the background
//        //dispatch_async(dispatc, block: () -> Void)
//        let queue = DispatchQueue(label: "LoadingCoreData")
//        queue.sync() {
//            () -> Void in
//            // get the documents directory..
//            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//            // Save the url location of the document directory
//            let docURL = urls[urls.endIndex-1]
//            
//            /* The directory the application uses to store the Core Data store file.
//             This code uses a file named "DataModel.sqlite" in the application's documents directory.
//             */
//            
//            // Name the SQL Lite file we are creating
//            self.dbURL = docURL.appendingPathComponent(self.sqlFilename) as NSURL!
//            
//            // Migrate to new DataModel
//            let options = [NSInferMappingModelAutomaticallyOption: true,
//                           NSMigratePersistentStoresAutomaticallyOption: true]
//            
//            do {
//                try self.mainStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.dbURL as URL?, options: options)
//            } catch {
//                fatalError("Error migrating store: \(error)")
//            }
//        }
    }
}


extension CoreDataStack {
//    internal func saveBackgroundContext() throws{
//        if backgroundContext.hasChanges{
//            do {
//                try backgroundContext.save()
//            }
//        }
//    }

    
//    internal func saveMainContext() throws {
//        print("CoreDataStack \(#line) Someone called save main context ")
////        fatalError()
//        if mainContext.hasChanges{
//            do {
//                try mainContext.save()
//            }
//        }
//    }
    
    
//    internal func savePersistingContext() throws{
//        if persistingContext.hasChanges{
//            do {
//                try persistingContext.save()
//            } 
//        }
//    }
    
    
    // Delete beers and Brewers with a batchrequest
//    internal func deleteBeersAndBreweries() -> Bool {
//        var success : Bool?
//        success = deleteFromCoreData(entity: "Beer", context: persistingContext)
//        guard success == true else {
//            return false
//        }
//        success = deleteFromCoreData(entity: "Beer", context: mainContext)
//        guard success == true else {
//            return false
//        }
//        success = deleteFromCoreData(entity: "Beer", context: backgroundContext)
//        guard success == true else {
//            return false
//        }
//        success = deleteFromCoreData(entity: "Brewery", context: backgroundContext)
//        guard success == true else {
//            return false
//        }
//        success = deleteFromCoreData(entity: "Brewery", context: mainContext)
//        guard success == true else {
//            return false
//        }
//        success = deleteFromCoreData(entity: "Brewery", context: persistingContext)
//        guard success == true else {
//            return false
//        }
//        // Remove all objects from contexts.
//        persistingContext.perform {
//            self.persistingContext.reset()
//        }
//        mainContext.perform {
//            self.mainContext.reset()
//        }
//        backgroundContext.perform {
//            self.backgroundContext.reset()
//        }
        //return true
    //}
    
    
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
        // We call this synchronously, but it's a very fast
        // operation (it doesn't hit the disk). We need to know
        // when it ends so we can call the next save (on the persisting
        // context). The last save might take some time and is done
        // in a background queue
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
            // Do not do this code.
//        backgroundContext.performAndWait(){
//            do{
//                try self.backgroundContext.save()
//            }catch{
//                fatalError("Error while saving background context: \(error)")
//            }
//            // Now we save the main
//            self.mainContext.performAndWait(){
//                do {
//                    try self.saveMainContext()
//                } catch {
//                    fatalError("Error while saving main context: \(error)")
//                }
//                // Finally save the persistentcontext
//                self.persistingContext.performAndWait(){
//                    do{
//                        try self.persistingContext.save()
//                    }catch{
//                        // BUG Occurs here when going to webpage
//                        // Dangling reference
//                        //fatalError("Error while saving persisting context: \(error)")
//                    }
//                }
//            }
//        }
   
}



