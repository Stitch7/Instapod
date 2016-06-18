//
//  PlayerRemoteProgressSliderScrubbingSpeed.swift
//  Instapod
//
//  Created by Christopher Reitz on 16.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

enum PlayerRemoteProgressSliderScrubbingSpeed: Float {
    case High = 1.0
    case Half = 0.5
    case Slow = 0.25
    case Fine = 0.1

    var allValues: [PlayerRemoteProgressSliderScrubbingSpeed] {
        return [
            High,
            Half,
            Slow,
            Fine,
        ]
    }

    var stringValue: String {
        // TODO: i18n
        switch self {
        case .High: return "High-Speed Scrubbing"
        case .Half: return "Half-Speed Scrubbing"
        case .Slow: return "Quarter-Speed Scrubbing"
        case .Fine: return "Fine Scrubbing"
        }
    }

    var offset: Float {
        switch self {
        case .High: return 0.0
        case .Half: return 50.0
        case .Slow: return 150.0
        case .Fine: return 225.0
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
        for (i, scrubbingSpeedOffset) in self.offsets.enumerate() {
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
