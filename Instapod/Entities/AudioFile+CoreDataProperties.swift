//
//  AudioFile+CoreDataProperties.swift
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

extension AudioFile {

    @NSManaged var data: NSData?
    @NSManaged var date: NSDate?
    @NSManaged var guid: String?
    @NSManaged var length: String?
    @NSManaged var type: String?
    @NSManaged var url: String?
    @NSManaged var episode: Episode?

}
