//
//  Image.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

struct Image {

    var url: URL
    var data: Data?
    var date: Date?
    var title: String?
    var thumbnail: Data?
    var thumbnail56: Data?
    var thumbnail72: Data?
    var color: UIColor?

    var isFetched = false

    init(url: URL) {
        self.url = url
    }

    init(managedObject: ImageManagedObject) {
        url = URL(string: managedObject.url!)!
        data = managedObject.data as Data?
        date = managedObject.date as Date?
        title = managedObject.title
        thumbnail = managedObject.thumbnail as Data?
        thumbnail56 = managedObject.thumbnail56 as Data?
        thumbnail72 = managedObject.thumbnail72 as Data?
        color = managedObject.color as? UIColor
    }

    func createImage(fromContext context: NSManagedObjectContext) -> ImageManagedObject {
        let image = context.createEntityWithName("Image") as! ImageManagedObject
        image.data = data
        image.date = date
        image.title = title
        image.url = url.absoluteString
        image.thumbnail = thumbnail
        image.thumbnail56 = thumbnail56
        image.thumbnail72 = thumbnail72
        image.color = color

        return image
    }
}
