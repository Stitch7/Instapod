//
//  PlayerRemoteProgressSliderScrubbingSpeed.swift
//  Instapod
//
//  Created by Christopher Reitz on 16.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PlayerRemoteProgressSliderScrubbingSpeed: Float {
    case high = 1.0
    case half = 0.5
    case slow = 0.25
    case fine = 0.1

    var allValues: [PlayerRemoteProgressSliderScrubbingSpeed] {
        return [
            .high,
            .half,
            .slow,
            .fine,
        ]
    }

    var stringValue: String {
        // TODO: i18n
        switch self {
        case .high: return "High-Speed Scrubbing"
        case .half: return "Half-Speed Scrubbing"
        case .slow: return "Quarter-Speed Scrubbing"
        case .fine: return "Fine Scrubbing"
        }
    }

    var offset: Float {
        switch self {
        case .high: return 0.0
        case .half: return 50.0
        case .slow: return 150.0
        case .fine: return 225.0
        }
    }

    var offsets: [Float] {
        var offsets = [Float]()
        for value in allValues {
            offsets.append(value.offset)
        }

        return offsets
    }

    func lowerScrubbingSpeed(forOffset offset: CGFloat) -> PlayerRemoteProgressSliderScrubbingSpeed? {
        var lowerScrubbingSpeedIndex: Int?
        for (i, scrubbingSpeedOffset) in self.offsets.enumerated() {
            if Float(offset) > scrubbingSpeedOffset {
                lowerScrubbingSpeedIndex = i
            }
        }

        if let newScrubbingSpeedIndex = lowerScrubbingSpeedIndex {
            if self != allValues[newScrubbingSpeedIndex] {
                return allValues[newScrubbingSpeedIndex]
            }
        }
        return nil
    }
}
