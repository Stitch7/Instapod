//
//  PodcastListViewMode.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PodcastListViewMode: Int, EnumIteratable {
    case tableView
    case collectionView

    var image: UIImage {
        var image: UIImage
        switch self {
        case .tableView: image = UIImage(named: "podcastViewModeTableView")!
        case .collectionView: image = UIImage(named: "podcastViewModeCollectionView")!
        }

        return image.withRenderingMode(.alwaysTemplate)
    }

    mutating func nextValue() {
        let sorted = PodcastListViewMode.values()
        let currentIndex = sorted.index(of: self)!
        var nextIndex = currentIndex + 1
        if sorted.count <= nextIndex {
            nextIndex = 0
        }

        self = sorted[nextIndex]
    }
}
