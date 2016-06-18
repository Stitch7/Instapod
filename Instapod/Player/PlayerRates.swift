//
//  PlayerRates.swift
//  Instapod
//
//  Created by Christopher Reitz on 15.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PlayerRates: Float {
    case Half = 0.5
    case Normal = 1.0
    case OneAndAHalf = 1.5
    case Double = 2.0
    case Triple = 3.0

    var sorted: [PlayerRates] {
        return [
            .Half,
            .Normal,
            .OneAndAHalf,
            .Double,
            .Triple
        ]
    }

    var image: UIImage {
        switch self {
        case .Half:        return UIImage(named: "playerRateHalf")!
        case .Normal:      return UIImage(named: "playerRateNormal")!
        case .OneAndAHalf: return UIImage(named: "playerRateOneAndAHalf")!
        case .Double:      return UIImage(named: "playerRateDouble")!
        case .Triple:      return UIImage(named: "playerRateTriple")!
        }
    }

    mutating func nextValue() -> Float {
        let sorted = self.sorted
        let currentIndex = sorted.indexOf(self)!
        var nextIndex = currentIndex + 1
        if sorted.count <= nextIndex {
            nextIndex = 0
        }

        self = sorted[nextIndex]
        return rawValue
    }
}
