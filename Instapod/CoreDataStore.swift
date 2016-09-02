//
//  CoreDataStore.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.11.15.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

class CoreDataStore {

    // MARK: - Properties

    let storeName: String!

    // MARK: - Initializer

    init(storeName: String) {
        self.storeName = storeName
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // Save Core Data store file to the application's documents directory
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count - 1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource(self.storeName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("\(self.storeName).sqlite")
        print(url)

//        if NSFileManager.defaultManager().fileExistsAtPath(url.path!) == false {
//            self.preloadDatabase()
//        }

        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."

            dict[NSUnderlyingErrorKey] = error as NSError
            let domain = NSBundle.mainBundle().bundleIdentifier
            let wrappedError = NSError(domain: domain!, code: 9999, userInfo: dict)
            // TODO: Replace this with code to handle the error appropriately.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        return managedObjectContext
    }()

    func preloadDatabase() {
        let mainBundle = NSBundle.mainBundle()
        let sourceURLs = [
            mainBundle.URLForResource(storeName, withExtension: "sqlite")!,
            mainBundle.URLForResource(storeName, withExtension: "sqlite-wal")!,
            mainBundle.URLForResource(storeName, withExtension: "sqlite-shm")!
        ]

        let destinationURLs = [
            applicationDocumentsDirectory.URLByAppendingPathComponent("\(storeName).sqlite"),
            applicationDocumentsDirectory.URLByAppendingPathComponent("\(storeName).sqlite-wal"),
            applicationDocumentsDirectory.URLByAppendingPathComponent("\(storeName).sqlite-shm")
        ]

        for i in 0..<sourceURLs.count {
            do {
                try NSFileManager.defaultManager().copyItemAtURL(sourceURLs[i], toURL: destinationURLs[i])
            } catch {
                print("ERROR: copy failed")
            }
        }
    }

    func deleteAllData(entity: String) {
        print("truncating table \(entity) ...")
        let fetchRequest = NSFetchRequest(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try managedObjectContext.executeFetchRequest(fetchRequest)
            for managedObject in results {
                let managedObjectData = managedObject as! NSManagedObject
                managedObjectContext.deleteObject(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // TODO: Replace this implementation with code to handle the error appropriately.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
}
