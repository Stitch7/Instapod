//
//  FeedParserAEXML.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.06.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import AEXML

class FeedParserAEXML: FeedParser {

    // MARK: - Properties

    var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en")
        dateFormatter.dateFormat = "EEE, dd MMMM yyyy HH:mm:ss z"
        return dateFormatter
    }

    var dateFormatter2: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en")
        dateFormatter.dateFormat = "dd MMMM yyyy HH:mm:ss z"

        return dateFormatter
    }

    // MARK: - FeedParser

    func nextPage(_ xmlData: Data) throws -> URL? {
        var url: URL?
        let xmlDocument = try AEXMLDocument(xml: xmlData)
        let channel = xmlDocument.root["channel"]

        if let links = channel["atom:link"].all {
            for link in links {
                guard link.attributes["rel"] == "next" else { continue }
                if let nextPage = link.attributes["href"] {
                    url = URL(string: nextPage)
                }
            }
        }

        return url
    }

    func parseFeed(uuid: String, url: URL, xmlData: Data) throws -> Podcast {
        let xmlDocument = try AEXMLDocument(xml: xmlData)
        let channel = xmlDocument.root["channel"]

        var podcast = Podcast(uuid: uuid, url: url)
        podcast.author = channel["itunes:author"].string
        podcast.category = channel["itunes:category"].string
        podcast.desc = channel["description"].string
        podcast.explicit = channel["explicit"].string == "yes"
        podcast.generator = channel["generator"].string
        podcast.language = channel["language"].string
        podcast.lastBuildDate = dateFormatter.date(from: channel["lastBuildDate"].string)
        podcast.pubDate = dateFormatter.date(from: channel["pubDate"].string)
        podcast.subtitle = channel["itunes:subtitle"].string
        podcast.summary = channel["itunes:summary"].string
        podcast.title = channel["title"].string

        return podcast
    }

    func parseImage(_ xmlData: Data) throws -> Image? {
        var feedImage: Image?
        let xmlDocument = try AEXMLDocument(xml: xmlData)
        let channel = xmlDocument.root["channel"]

        if let
            imageUrlString = channel["itunes:image"].attributes["href"],
            let url = URL(string: imageUrlString)
        {
            feedImage = Image(url: url)
        }

        return feedImage
    }

    func parseEpisodes(_ xmlData: Data) throws -> [Episode]? {
        var feedEpisodes: [Episode]?
        let xmlDocument = try AEXMLDocument(xml: xmlData)
        let channel = xmlDocument.root["channel"]

        guard let items = channel["item"].all else { return [] }

        feedEpisodes = [Episode]()
        for item in items {
            var episode = Episode()
            episode.author = item["itunes:author"].string
            episode.content = item["content:encoded"].string
            episode.desc = item["description"].string
            episode.duration = item["itunes:duration"].string
            episode.link = item["link"].string
            episode.subtitle = item["itunes:subtitle"].string
            episode.summary = item["itunes:summary"].string
            episode.title = item["title"].string

            let pubDate = item["pubDate"].string
            episode.pubDate = dateFormatter.date(from: pubDate) ?? dateFormatter2.date(from: pubDate)

            if let
                episodeImageUrlString = item["itunes:image"].attributes["href"],
                let episodeImageUrl = URL(string: episodeImageUrlString)
            {
//                if let feedImage = feed.image {
//                    if feedImage.url.absoluteString != episodeImageUrlString {
//                        episode.image = FeedImage(url: episodeImageUrl)
//                    }
//                }
//                else {
                    episode.image = Image(url: episodeImageUrl)
//                }
            }

            let enclosure = item["enclosure"]
            var audioFile = AudioFile()
            audioFile.length = enclosure.attributes["length"]
            audioFile.type = enclosure.attributes["type"]

            if let
                urlString = enclosure.attributes["url"],
                let url = URL(string: urlString)
            {
                audioFile.url = url
            }

            episode.audioFile = audioFile

            feedEpisodes!.append(episode)
//                delegate?.feedParser(self, didFinishWithEpisode: episode)
        }

        return feedEpisodes
    }
}
