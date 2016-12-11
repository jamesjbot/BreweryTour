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
    private var model: NSManagedObjectModel!
    internal var mainStoreCoordinator: NSPersistentStoreCoordinator!
    private var modelURL: NSURL!
    private var dbURL: NSURL!
    internal var persistingContext: NSManagedObjectContext!
    public var backgroundContext : NSManagedObjectContext!
    internal var mainContext: NSManagedObjectContext!
    
    // MARK: - Initializers
    init?(modelName: String) {
        super.init()
        // This resource is the same name as your xcdatamodeld contained in your project.
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        
        // Save the modelURL
        self.modelURL = modelURL as NSURL!
        
        // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }
        
        // Save the managedObjectModel
        self.model = mom
        
        // Create the persistent store coordinator
        mainStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
        
        // Create the persisting context
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        
        // TODO Change the name of this as we are not using it as storage anymore
        // Assign coordinator to persisting context
        persistingContext.persistentStoreCoordinator = mainStoreCoordinator
        
        // Create Managed Ojbect Context running on the MainQueue
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        // TODO Don't need contextCommunicating wih one another
        mainContext.parent = persistingContext
        
        // TODO Delete this as we don't need a background context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = mainContext


        
        // Add an SQL lite store in the documents folder
        // Create the SQL Store in the background
        //dispatch_async(dispatc, block: () -> Void)
        let queue = DispatchQueue(label: "LoadingCoreData")
        queue.sync() {
            () -> Void in
            // get the documents directory..
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            // Save the url location of the document directory
            let docURL = urls[urls.endIndex-1]
            
            /* The directory the application uses to store the Core Data store file.
             This code uses a file named "DataModel.sqlite" in the application's documents directory.
             */
            
            // Name the SQL Lite file we are creating
            self.dbURL = docURL.appendingPathComponent(self.sqlFilename) as NSURL!
            
            // Migrate to new DataModel with photoalbum
            let options = [NSInferMappingModelAutomaticallyOption: true,
                           NSMigratePersistentStoresAutomaticallyOption: true]
            
            do {
                try self.mainStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: self.dbURL as URL?, options: options)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }
}


extension CoreDataStack {
    internal func saveBackgroundContext() throws{
        if backgroundContext.hasChanges{
            do {
                try backgroundContext.save()
            }
        }
    }
    
    
    internal func saveMainContext() throws{
        if mainContext.hasChanges{
            do {
                try mainContext.save()
            }
        }
    }
    
    
    internal func savePersistingContext() throws{
        if persistingContext.hasChanges{
            do {
                try persistingContext.save()
            } 
        }
    }
    
    
    // Temporary test code
    internal func stateOfAllContexts(){

        do {
            let request : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
            request.sortDescriptors = []
            try print("persistent Breweries: \(persistingContext.count(for: request))")
            try print("background Breweries: \(backgroundContext.count(for: request))")
            //try print("favorites Breweries: \(favoritesContext.count(for: request))")
            
            let brequest : NSFetchRequest<Beer> = NSFetchRequest(entityName: "Beer")
            brequest.sortDescriptors = []
            try print("persisting Beers: \(persistingContext.count(for: request))")
            try print("background Beers: \(backgroundContext.count(for: brequest))")
            //try print("favorite Beers: \(favoritesContext.count(for: brequest))")
            
            let srequest : NSFetchRequest<Style> = NSFetchRequest(entityName: "Style")
            srequest.sortDescriptors = []
            try print("persisting Styles: \(persistingContext.count(for: request))")
            try print("background Styles: \(backgroundContext.count(for: srequest))")
            //try print("favorite Styles: \(favoritesContext.count(for: srequest))")
            
        } catch {
            
        }
    }
    
    // Temporary test code
    internal func deleteBeersAndBreweries() -> Bool {
        stateOfAllContexts()
        var success = deleteFromCoreData(entity: "Beer", context: persistingContext)
        guard success == true else {
            return false
        }
//        let beerRequest : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Beer")
//        let beerBatch = NSBatchDeleteRequest(fetchRequest: beerRequest as! NSFetchRequest<NSFetchRequestResult> )
//        beerBatch.resultType = .resultTypeCount
//        do {
//            try mainStoreCoordinator.execute(beerBatch, with: persistingContext)
//            let results = try backgroundContext.execute(beerBatch) as! NSBatchDeleteResult
//            print("Batch Deleted completed on \(results.result) objects")
//            try persistingContext.save()
//            try backgroundContext.save()
//        } catch {
//            fatalError("batchdelete failed")
//        }
        success = deleteFromCoreData(entity: "Brewery", context: persistingContext)
//        let breweryRequest : NSFetchRequest<Brewery> = NSFetchRequest(entityName: "Brewery")
//        let breweryBatch = NSBatchDeleteRequest(fetchRequest: breweryRequest as! NSFetchRequest<NSFetchRequestResult> )
//        do {
//            let results = try backgroundContext.execute(breweryBatch) as! NSBatchDeleteResult
//            try mainStoreCoordinator.execute(breweryBatch, with: (backgroundContext)!)
//            print("Batch Deleted completed on \(results.result) objects")
//            try backgroundContext.save()
//        } catch {
//            return false
//            fatalError("batchdelete failed")
//        }
        guard success == true else {
            return false
        }
        
        persistingContext.reset()
        backgroundContext.reset()
        stateOfAllContexts()
        
        return true
    }
    
    
    // This function delete all the entities from core data.
    private func deleteFromCoreData(entity: String, context: NSManagedObjectContext) -> Bool {
        let genericRequest : NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "\(entity)")
        let genericBatchDelete = NSBatchDeleteRequest(fetchRequest: genericRequest)
        genericBatchDelete.resultType = .resultTypeCount
        do {
            let results = try backgroundContext.execute(genericBatchDelete) as! NSBatchDeleteResult
            try context.save()
            return true
        } catch let error {
            return false
        }
    }
    
    
    private func saveToFile() {
        // We call this synchronously, but it's a very fast
        // operation (it doesn't hit the disk). We need to know
        // when it ends so we can call the next save (on the persisting
        // context). The last save might take some time and is done
        // in a background queue
        
        backgroundContext.performAndWait(){
            do{
                try self.backgroundContext.save()
            }catch{
                fatalError("Error while saving background context: \(error)")
            }
            // Now we save the main
            self.mainContext.performAndWait(){
                do {
                    try self.saveMainContext()
                } catch {
                    fatalError("Error while saving main context: \(error)")
                }
                // Finally save the persistentcontext
                self.persistingContext.performAndWait(){
                    do{
                        try self.persistingContext.save()
                    }catch{
                        fatalError("Error while saving persisting context: \(error)")
                    }
                }
            }
        }
    }
}



