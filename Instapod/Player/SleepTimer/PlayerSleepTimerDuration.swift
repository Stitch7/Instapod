//
//  PlayerSleepTimerDuration.swift
//  Instapod
//
//  Created by Christopher Reitz on 17.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PlayerSleepTimerDuration: Int {
    case off = 0
    case fiveMinutes = 5
    case tenMinutes = 10
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case oneHour = 60
    case twoHours = 120

    var sorted: [PlayerSleepTimerDuration] {
        return [
            .off,
            .fiveMinutes,
            .tenMinutes,
            .fifteenMinutes,
            .thirtyMinutes,
            .oneHour,
            .twoHours
        ]
    }

    var seconds: Int {
        return self.rawValue * 60
    }

    var image: UIImage {
        let selfChars = String(describing: self).characters
        let first = String(selfChars.prefix(1)).capitalized
        let other = String(selfChars.dropFirst())
        let suffix = first + other
        return UIImage(named: "playerSleepTimerDuration\(suffix)")!
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
