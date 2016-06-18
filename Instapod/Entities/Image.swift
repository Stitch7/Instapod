//
//  Image.swift
//  
//
//  Created by Christopher Reitz on 12.03.16.
//
//

import Foundation
import CoreData


class Image: NSManagedObject {
    var nsURL: NSURL? {
        guard let urlString = self.url else { return nil }
        return NSURL(string: urlString)
    }
}
