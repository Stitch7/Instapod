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

    var url: NSURL
    var data: NSData?
    var date: NSDate?
    var title: String?
    var thumbnail: NSData?
    var thumbnail56: NSData?
    var thumbnail72: NSData?
    var color: UIColor?

    var isFetched = false

    init(url: NSURL) {
        self.url = url
    }

    init(managedObject: ImageManagedObject) {
        url = NSURL(string: managedObject.url!)!
        data = managedObject.data
        date = managedObject.date
        title = managedObject.title
        thumbnail = managedObject.thumbnail
        thumbnail56 = managedObject.thumbnail56
        thumbnail72 = managedObject.thumbnail72
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
