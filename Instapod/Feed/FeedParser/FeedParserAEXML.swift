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

    var dateFormatter: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en")
        dateFormatter.dateFormat = "EEE, dd MMMM yyyy HH:mm:ss z"
        return dateFormatter
    }

    var dateFormatter2: NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en")
        dateFormatter.dateFormat = "dd MMMM yyyy HH:mm:ss z"

        return dateFormatter
    }

    // MARK: - FeedParser

    func nextPage(xmlData: NSData) throws -> NSURL? {
        var url: NSURL?
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        if let links = channel["atom:link"].all {
            for link in links {
                guard link.attributes["rel"] == "next" else { continue }
                if let nextPage = link.attributes["href"] {
                    url = NSURL(string: nextPage)
                }
            }
        }

        return url
    }

    func parseFeed(uuid uuid: String, url: NSURL, xmlData: NSData) throws -> Podcast {
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        var podcast = Podcast(uuid: uuid, url: url)
        podcast.author = channel["itunes:author"].string
        podcast.category = channel["itunes:category"].string
        podcast.desc = channel["description"].string
        podcast.explicit = channel["explicit"].string == "yes"
        podcast.generator = channel["generator"].string
        podcast.language = channel["language"].string
        podcast.lastBuildDate = dateFormatter.dateFromString(channel["lastBuildDate"].string ?? "")
        podcast.pubDate = dateFormatter.dateFromString(channel["pubDate"].string ?? "")
        podcast.subtitle = channel["itunes:subtitle"].string
        podcast.summary = channel["itunes:summary"].string
        podcast.title = channel["title"].string

        return podcast
    }

    func parseImage(xmlData: NSData) throws -> Image? {
        var feedImage: Image?
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        if let
            imageUrlString = channel["itunes:image"].attributes["href"],
            url = NSURL(string: imageUrlString)
        {
            feedImage = Image(url: url)
        }

        return feedImage
    }

    func parseEpisodes(xmlData: NSData) throws -> [Episode]? {
        var feedEpisodes: [Episode]?
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
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

            let pubDate = item["pubDate"].string ?? ""
            episode.pubDate = dateFormatter.dateFromString(pubDate) ?? dateFormatter2.dateFromString(pubDate)

            if let
                episodeImageUrlString = item["itunes:image"].attributes["href"],
                episodeImageUrl = NSURL(string: episodeImageUrlString)
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
                url = NSURL(string: urlString)
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