//
//  NSManagedObjectContext+createEntityWithName.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
    func createEntityWithName(name: String) -> NSManagedObject {
        return NSEntityDescription.insertNewObjectForEntityForName(name, inManagedObjectContext: self)
    }
}
