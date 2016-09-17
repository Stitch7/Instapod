//
//  NSManagedObjectContext+createEntityWithName.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func createEntityWithName(_ name: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObject(forEntityName: name, into: self)
    }
}
