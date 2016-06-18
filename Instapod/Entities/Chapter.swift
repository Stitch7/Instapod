//
//  Chapter.swift
//  
//
//  Created by Christopher Reitz on 12.03.16.
//
//

import Foundation
import CoreData


class Chapter: NSManagedObject {
    
    @NSManaged var no: NSNumber?
    @NSManaged var start: String?
    @NSManaged var title: String?
    @NSManaged var episode: Episode?

    var startFormatted: String {
        guard let start = self.start else { return "" }

        var parts = start.characters.split{ $0 == ":" || $0 == "." }.map(String.init)
        parts.removeAtIndex(parts.count - 1)
        return parts.filter{ $0 != "00" }.joinWithSeparator(":")
    }

    var seconds: Double {
        var seconds = 0.0
        guard let start = self.start else { return seconds }

        let parts = start.characters.split{ $0 == ":" || $0 == "." }.map(String.init).map{ Int($0)! }
        var units = [String: Int](minimumCapacity: parts.count)
        let unitLabels = ["h", "m", "s", "ms"]
        for i in 0..<parts.count {
            units[unitLabels[i]] = parts[i]
        }

        if let ms = units["ms"] { seconds += Double(ms) / 1000.0 }
        if let s = units["s"] { seconds += Double(s) }
        if let m = units["m"] { seconds += Double(m) * 60.0 }
        if let h = units["h"] { seconds += Double(h) * 60.0 * 60.0 }

        return seconds
    }

}
