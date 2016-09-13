
//
//  PodcastListEditingMode.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

enum PodcastListEditingMode: Int, EnumIteratable {
    case on
    case off

    var boolValue: Bool {
        switch self {
        case .on: return true
        case .off: return false
        }
    }

    mutating func nextValue() -> Int {
        let sorted = PodcastListEditingMode.values()
        let currentIndex = sorted.indexOf(self)!
        var nextIndex = currentIndex + 1
        if sorted.count <= nextIndex {
            nextIndex = 0
        }

        self = sorted[nextIndex]
        return rawValue
    }
}
