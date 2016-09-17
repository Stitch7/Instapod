//
//  ImageManagedObject+CoreDataProperties.swift
//  
//
//  Created by Christopher Reitz on 08.09.16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ImageManagedObject {

    @NSManaged var color: NSObject?
    @NSManaged var data: Data?
    @NSManaged var date: Date?
    @NSManaged var thumbnail56: Data?
    @NSManaged var thumbnail72: Data?
    @NSManaged var title: String?
    @NSManaged var url: String?
    @NSManaged var thumbnail: Data?
    @NSManaged var episodes: Set<EpisodeManagedObject>?
    @NSManaged var podcast: PodcastManagedObject?

}
