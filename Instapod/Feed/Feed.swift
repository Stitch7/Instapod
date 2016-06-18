//
//  Feed.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import CoreData

final class Feed {
    var url: NSURL
    var nextPage: NSURL?
    var author: String?
    var category: String?
    var desc: String?
    var explicit: NSNumber?
    var generator: String?
    var language: String?
    var lastBuildDate: NSDate?
    var pubDate: NSDate?
    var sortIndex: NSNumber?
    var subtitle: String?
    var summary: String?
    var title: String?
    var episodes: [FeedEpisode]?
    var image: FeedImage?

    init(url: NSURL) {
        self.url = url
    }

    var allImagesAreFetched: Bool {
        guard image != nil else { return false }
        guard let episodes = self.episodes else { return true }

        for episode in episodes {
            guard let episodeImage = episode.image else { continue }
            if episodeImage.isFetched == false {
                return false
            }
        }
        return true
    }

    func createPodcast(fromContext context: NSManagedObjectContext) -> Podcast {
        let podcast = context.createEntityWithName("Podcast") as! Podcast
        podcast.author = author
        podcast.category = category
        podcast.desc = desc
        podcast.explicit = explicit
        podcast.generator = generator
        podcast.language = language
        podcast.lastBuildDate = lastBuildDate
        podcast.pubDate = pubDate
        podcast.subtitle = subtitle
        podcast.summary = summary
        podcast.title = title
        podcast.url = url.absoluteString
        podcast.image = image?.createImage(fromContext: context)

        if let episodes = self.episodes {
            for feedEpisode in episodes {
                let episode = feedEpisode.createEpisode(fromContext: context)
                podcast.addObject(episode, forKey: "episodes")
            }
        }

        return podcast
    }
}

final class FeedEpisode {
    var author: String?
    var content: String?
    var desc: String?
    var duration: String?
    var link: String?
    var pubDate: NSDate?
    var subtitle: String?
    var summary: String?
    var title: String?
    var chapters: NSSet?
    var image: FeedImage?
    var audioFile: FeedAudioFile?

    func createEpisode(fromContext context: NSManagedObjectContext) -> Episode {
        let episode = context.createEntityWithName("Episode") as! Episode
        episode.author = author
        episode.content = content
        episode.desc = desc
        episode.duration = duration
        episode.link = link
        episode.pubDate = pubDate
        episode.subtitle = subtitle
        episode.summary = summary
        episode.title = title
        episode.chapters = chapters
        episode.image = image?.createImage(fromContext: context)
        episode.audioFile = audioFile?.createAudioFile(fromContext: context)

        return episode
    }
}

final class FeedImage {
    var url: NSURL
    var data: NSData?
    var date: NSDate?
    var title: String?
    var thumbnail72: NSData?
    var thumbnail56: NSData?
    var color: UIColor?

    var isFetched = false

    init(url: NSURL) {
        self.url = url
    }

    func createImage(fromContext context: NSManagedObjectContext) -> Image {
        let image = context.createEntityWithName("Image") as! Image
        image.data = data
        image.date = date
        image.title = title
        image.url = url.absoluteString
        image.thumbnail72 = thumbnail72
        image.thumbnail56 = thumbnail56
        image.color = color

        return image
    }
}

final class FeedAudioFile {
    var length: String?
    var type: String?
    var url: String?

    func createAudioFile(fromContext context: NSManagedObjectContext) -> AudioFile {
        let audioFile = context.createEntityWithName("AudioFile") as! AudioFile
        audioFile.length = length
        audioFile.type = type
        audioFile.url = url

        return audioFile
    }
}
