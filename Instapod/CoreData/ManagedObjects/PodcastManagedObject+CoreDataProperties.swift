//
//  PodcastManagedObject+CoreDataProperties.swift
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

extension PodcastManagedObject {

    @NSManaged var author: String?
    @NSManaged var category: String?
    @NSManaged var desc: String?
    @NSManaged var explicit: NSNumber?
    @NSManaged var generator: String?
    @NSManaged var language: String?
    @NSManaged var lastBuildDate: NSDate?
    @NSManaged var pubDate: NSDate?
    @NSManaged var sortIndex: NSNumber?
    @NSManaged var subtitle: String?
    @NSManaged var summary: String?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var episodes: Set<EpisodeManagedObject>?
    @NSManaged var image: ImageManagedObject?

}
