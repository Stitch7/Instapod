//
//  Image+CoreDataProperties.swift
//  
//
//  Created by Christopher Reitz on 24.03.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Image {

    @NSManaged var data: NSData?
    @NSManaged var date: NSDate?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var thumbnail72: NSData?
    @NSManaged var thumbnail56: NSData?
    @NSManaged var color: NSObject?
    @NSManaged var episodes: NSSet?
    @NSManaged var podcast: Podcast?

}
