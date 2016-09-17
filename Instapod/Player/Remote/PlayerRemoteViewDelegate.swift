//
//  PlayerRemoteViewDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 15.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

protocol PlayerRemoteViewDelegate: class {
    func playerRate(_ rate: Float)
    func startSleepTimer(withDuration duration: PlayerSleepTimerDuration)
    func shareEpisode() -> Episode
}
