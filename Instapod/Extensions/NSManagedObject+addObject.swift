//
//  NSManagedObject+addObject.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreData

extension NSManagedObject {
    func addObject(value: NSManagedObject, forKey: String) {
        let items = self.mutableSetValueForKey(forKey)
        items.addObject(value)
    }
}
