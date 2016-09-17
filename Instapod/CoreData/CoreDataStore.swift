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

    let storeName: String

    // MARK: - Initializer

    init(storeName: String) {
        self.storeName = storeName
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // Save Core Data store file to the application's documents directory
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count - 1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.storeName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        let url = self.applicationDocumentsDirectory.appendingPathComponent("\(self.storeName).sqlite")
        print(url)

//        if NSFileManager.defaultManager().fileExistsAtPath(url.path!) == false {
//            self.preloadDatabase()
//        }

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
        } catch {
            // Report any error we got
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data." as AnyObject?

            dict[NSUnderlyingErrorKey] = error as NSError
            let domain = Bundle.main.bundleIdentifier
            let wrappedError = NSError(domain: domain!, code: 9999, userInfo: dict)
            // TODO: Replace this with code to handle the error appropriately.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }

        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        return managedObjectContext
    }()

    func preloadDatabase() {
        let mainBundle = Bundle.main
        let sourceURLs = [
            mainBundle.url(forResource: storeName, withExtension: "sqlite")!,
            mainBundle.url(forResource: storeName, withExtension: "sqlite-wal")!,
            mainBundle.url(forResource: storeName, withExtension: "sqlite-shm")!
        ]

        let destinationURLs = [
            applicationDocumentsDirectory.appendingPathComponent("\(storeName).sqlite"),
            applicationDocumentsDirectory.appendingPathComponent("\(storeName).sqlite-wal"),
            applicationDocumentsDirectory.appendingPathComponent("\(storeName).sqlite-shm")
        ]

        for i in 0..<sourceURLs.count {
            do {
                try FileManager.default.copyItem(at: sourceURLs[i], to: destinationURLs[i])
            } catch {
                print("ERROR: copy failed")
            }
        }
    }

    func deleteAllData(_ entity: String) {

        print("truncating table \(entity) ...")

        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false

        do {
            let results = try managedObjectContext.fetch(fetchRequest)
            for managedObject in results {
                managedObjectContext.delete(managedObject)
            }
            try managedObjectContext.save()
            managedObjectContext.reset()
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
