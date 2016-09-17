//
//  PlayerRates.swift
//  Instapod
//
//  Created by Christopher Reitz on 15.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PlayerRates: Float, EnumIteratable {
    case half = 0.5
    case normal = 1.0
    case oneAndAHalf = 1.5
    case double = 2.0
    case triple = 3.0

    var sorted: [PlayerRates] {
        return [
            .half,
            .normal,
            .oneAndAHalf,
            .double,
            .triple
        ]
    }

    var image: UIImage {
        switch self {
        case .half:        return UIImage(named: "playerRateHalf")!
        case .normal:      return UIImage(named: "playerRateNormal")!
        case .oneAndAHalf: return UIImage(named: "playerRateOneAndAHalf")!
        case .double:      return UIImage(named: "playerRateDouble")!
        case .triple:      return UIImage(named: "playerRateTriple")!
        }
    }

    mutating func nextValue() {
        let sorted = self.sorted
        let currentIndex = sorted.index(of: self)!
        var nextIndex = currentIndex + 1
        if sorted.count <= nextIndex {
            nextIndex = 0
        }

        self = sorted[nextIndex]
    }
}
