//
//  PlayerSleepTimer.swift
//  Instapod
//
//  Created by Christopher Reitz on 17.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

final class PlayerSleepTimer {

    var interval = 0
    var timer = Timer()
    var intervalHandler: ((_ interval: Int) -> ())?
    var completionHandler: (() -> ())?

    func start(
        withDuration duration: PlayerSleepTimerDuration,
        interval intervalHandler: @escaping (_ interval: Int) -> (),
        completion completionHandler: @escaping () -> ()
    ) {
        interval = duration.seconds
        self.intervalHandler = intervalHandler
        self.completionHandler = completionHandler
        
        stop()
        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                                       target: self,
                                                       selector: #selector(timerDuration),
                                                       userInfo: nil,
                                                       repeats: true)
    }

    func stop() {
        timer.invalidate()
    }

    @objc func timerDuration() {
        interval -= 1
        if let intervalHandler = self.intervalHandler {
            intervalHandler(interval)
        }

        if interval <= 0 {
            stop()
            if let completionHandler = self.completionHandler {
                completionHandler()
            }
        }
    }
}
