//
//  CMTime+stringValue.swift
//  Instapod
//
//  Created by Christopher Reitz on 08.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreMedia

extension CMTime {
    var stringValue: String {
        let totalSeconds = CMTimeGetSeconds(self)
        let hours = Int(floor(totalSeconds / 3600))
        let minutes = Int(floor(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60))
        let seconds = Int(floor((totalSeconds.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60)))
//        let minutes = Int(floor(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60))
//        let seconds = Int(floor((totalSeconds % 3600).truncatingRemainder(dividingBy: 60)))

        return String(format: "%i:%02i:%02i", hours, minutes, seconds)
    }

    var shortStringValue: String {
        let totalSeconds = CMTimeGetSeconds(self)
        let hours = Int(floor(totalSeconds / 3600))
        let minutes = Int(floor(totalSeconds.truncatingRemainder(dividingBy: 3600) / 60))
        let seconds = Int(floor((totalSeconds.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60)))

        if hours > 0 {
            return String(format: "%i:%02i:%02i", hours, minutes, seconds)
        }
        else {
            return String(format: "%i:%02i", minutes, seconds)
        }
    }
}
