//
//  PlayerSleepTimerDuration.swift
//  Instapod
//
//  Created by Christopher Reitz on 17.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PlayerSleepTimerDuration: Int {
    case Off = 0
    case FiveMinutes = 5
    case TenMinutes = 10
    case FifteenMinutes = 15
    case ThirtyMinutes = 30
    case OneHour = 60
    case TwoHours = 120

    var sorted: [PlayerSleepTimerDuration] {
        return [
            .Off,
            .FiveMinutes,
            .TenMinutes,
            .FifteenMinutes,
            .ThirtyMinutes,
            .OneHour,
            .TwoHours
        ]
    }

    var seconds: Int {
        return self.rawValue * 60
    }

    var image: UIImage {
        return UIImage(named: "playerSleepTimerDuration\(self)")!
    }

    mutating func nextValue() -> Int {
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
