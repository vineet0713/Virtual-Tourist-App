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
    
    // MARK: - Initializer
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
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
    
}
