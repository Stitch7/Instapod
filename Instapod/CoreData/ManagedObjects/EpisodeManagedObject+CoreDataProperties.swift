//
//  EpisodeManagedObject+CoreDataProperties.swift
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

extension EpisodeManagedObject {

    @NSManaged var author: String?
    @NSManaged var content: String?
    @NSManaged var desc: String?
    @NSManaged var duration: String?
    @NSManaged var link: String?
    @NSManaged var pubDate: Date?
    @NSManaged var subtitle: String?
    @NSManaged var summary: String?
    @NSManaged var title: String?
    @NSManaged var audioFile: AudioFileManagedObject?
    @NSManaged var image: ImageManagedObject?
    @NSManaged var podcast: PodcastManagedObject?

}
