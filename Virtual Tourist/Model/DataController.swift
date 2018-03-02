//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Vineet Joshi on 2/25/18.
//  Copyright © 2018 Vineet Joshi. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    // MARK: - Properties
    
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!
    
    // MARK: - Initializer
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    // MARK: - Configure Contexts
    
    func configureContexts() {
        // creates a context that is associated with the private queue (instead of the main queue!)
        // this is helpful because we do NOT want slow work on the main queue
        backgroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        // sets the Merge Policy (if there are merge conflicts between the viewContext and backgroundContext)
        // by default, the Merge Policy is set so that app will crash!
        
        // we will consider the work done on the background thread to be the authoritative version of our data!
        
        // so the backgroundContext will prefer its own property values in case of a conflict
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        // so the viewContext will prefer the property values from the Persistent Store
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> DataController {
        struct Singleton {
            static var sharedInstance = DataController(modelName: "Virtual_Tourist")
        }
        return Singleton.sharedInstance
    }
    
    // MARK: - Load
    
    func load(completion: (()->Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
            completion?()
        }
    }
    
    // MARK: - Save
    
    func saveViewContext() -> Bool {
        do {
            try viewContext.save()
        } catch {
            return false
        }
        return true
    }
    
    func saveBackgroundContext() -> Bool {
        do {
            try backgroundContext.save()
        } catch {
            return false
        }
        return true
    }
    
}
