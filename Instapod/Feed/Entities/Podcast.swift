//
//  Feed.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import CoreData

struct Podcast {

    // MARK: - Properties

    var id: URL?
    let uuid: String
    var nextPage: URL?
    var url: URL
    var author: String?
    var category: String?
    var desc: String?
    var explicit: Bool?
    var generator: String?
    var language: String?
    var lastBuildDate: Date?
    var pubDate: Date?
    var sortIndex: NSNumber?
    var subtitle: String?
    var summary: String?
    var title: String?
    var image: Image?
    var episodes: [Episode]?

    // MARK: - Initializers

    init(uuid: String, url: URL) {
        self.uuid = uuid
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

    mutating func updateEpisode(with newEpisode: Episode) {
        guard let episodes = self.episodes else { return }

        for (key, episode) in episodes.enumerated() {
            if episode.title == newEpisode.title && episode.desc == newEpisode.desc {
                self.episodes![key] = newEpisode
            }
        }
    }

    func createPodcast(fromContext context: NSManagedObjectContext) -> PodcastManagedObject {
        let podcast = context.createEntityWithName("Podcast") as! PodcastManagedObject
        podcast.url = url.absoluteString
        podcast.author = author
        podcast.category = category
        podcast.desc = desc
        podcast.explicit = explicit as NSNumber?
        podcast.generator = generator
        podcast.language = language
        podcast.lastBuildDate = lastBuildDate
        podcast.pubDate = pubDate
        podcast.subtitle = subtitle
        podcast.summary = summary
        podcast.title = title
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

extension Podcast {
    init(managedObject: PodcastManagedObject) {
        id = managedObject.objectID.uriRepresentation()
        uuid = UUID().uuidString

        url = URL(string: managedObject.url!)!
        author = managedObject.author
        category = managedObject.category
        desc = managedObject.desc
        explicit = managedObject.explicit as Bool?
        generator = managedObject.generator
        language = managedObject.language
        lastBuildDate = managedObject.lastBuildDate as Date?
        pubDate = managedObject.pubDate as Date?
        sortIndex = managedObject.sortIndex
        subtitle = managedObject.subtitle
        summary = managedObject.summary
        title = managedObject.title

        if let managedImage = managedObject.image {
            image = Image(managedObject: managedImage)
        }

        episodes = [Episode]()
        if let managedEpisodes = managedObject.episodes {
            for managedEpisode in managedEpisodes {
                var episode = Episode(managedObject: managedEpisode)
                var podcast = self
                podcast.episodes = nil
                episode.podcast = podcast
                episodes?.append(episode)
            }
        }
    }
}
