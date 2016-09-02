//
//  Episode+CoreDataProperties.swift
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

extension Episode {

    @NSManaged var author: String?
    @NSManaged var content: String?
    @NSManaged var desc: String?
    @NSManaged var duration: String?
    @NSManaged var link: String?
    @NSManaged var pubDate: NSDate?
    @NSManaged var subtitle: String?
    @NSManaged var summary: String?
    @NSManaged var title: String?
    @NSManaged var audioFile: AudioFile?
    @NSManaged var image: Image?
    @NSManaged var podcast: Podcast?

}
