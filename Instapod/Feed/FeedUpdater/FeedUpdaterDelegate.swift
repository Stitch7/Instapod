//
//  FeedUpdaterDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 08.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//
//
protocol FeedUpdaterDelegate: class {
    func feedUpdater(_ feedupdater: FeedUpdater, didFinishWithEpisode: Episode, ofPodcast podcast: Podcast)
    func feedUpdater(_ feedupdater: FeedUpdater, didFinishWithNumberOfEpisodes numberOfEpisodes: Int)
}
