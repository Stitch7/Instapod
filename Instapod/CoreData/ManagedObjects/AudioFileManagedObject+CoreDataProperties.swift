//
//  AudioFileManagedObject+CoreDataProperties.swift
//  
//
//  Created by Christopher Reitz on 02.09.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension AudioFileManagedObject {

    @NSManaged var data: Data?
    @NSManaged var date: Date?
    @NSManaged var guid: String?
    @NSManaged var length: String?
    @NSManaged var type: String?
    @NSManaged var url: String?
    @NSManaged var episode: EpisodeManagedObject?

}
