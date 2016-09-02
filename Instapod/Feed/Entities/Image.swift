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
    var thumbnail72: NSData?
    var thumbnail56: NSData?
    var color: UIColor?

    var isFetched = false

    init(url: NSURL) {
        self.url = url
    }

    func createImage(fromContext context: NSManagedObjectContext) -> ImageManagedObject {
        let image = context.createEntityWithName("Image") as! ImageManagedObject
        image.data = data
        image.date = date
        image.title = title
        image.url = url.absoluteString
        image.thumbnail72 = thumbnail72
        image.thumbnail56 = thumbnail56
        image.color = color

        return image
    }
}
