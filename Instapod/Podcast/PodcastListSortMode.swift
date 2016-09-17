//
//  PodcastListSortMode.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

enum PodcastListSortMode: Int, EnumIteratable {
    case title
    case unplayed

    mutating func nextValue() {
        let sorted = PodcastListSortMode.values()
        let currentIndex = sorted.index(of: self)!
        var nextIndex = currentIndex + 1
        if sorted.count <= nextIndex {
            nextIndex = 0
        }

        self = sorted[nextIndex]
    }
}
