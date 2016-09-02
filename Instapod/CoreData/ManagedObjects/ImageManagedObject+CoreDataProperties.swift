//
//  ImageManagedObject+CoreDataProperties.swift
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

extension ImageManagedObject {

    @NSManaged var color: NSObject?
    @NSManaged var data: NSData?
    @NSManaged var date: NSDate?
    @NSManaged var thumbnail56: NSData?
    @NSManaged var thumbnail72: NSData?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var episodes: NSSet?
    @NSManaged var podcast: PodcastManagedObject?

}
