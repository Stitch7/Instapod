//
//  Chapter+CoreDataProperties.swift
//  
//
//  Created by Christopher Reitz on 23.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Chapter {

    @NSManaged var no: NSNumber?
    @NSManaged var start: String?
    @NSManaged var title: String?
    @NSManaged var episode: Episode?

}
