//
//  ImageManagedObject.swift
//  
//
//  Created by Christopher Reitz on 02.09.16.
//
//

import Foundation
import CoreData

class ImageManagedObject: NSManagedObject {
    var nsURL: NSURL? {
        guard let urlString = self.url else { return nil }
        return NSURL(string: urlString)
    }
}
