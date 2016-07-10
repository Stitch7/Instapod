//
//  FeedParserAEXML.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.06.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import AEXML

struct FeedParserAEXML: FeedParser {

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

    func parseFeed(url url: NSURL, xmlData: NSData) throws -> Feed {
        var feed: Feed
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        var newFeed = Feed(url: url)
        newFeed.author = channel["itunes:author"].string
        newFeed.category = channel["itunes:category"].string
        newFeed.desc = channel["description"].string
        newFeed.explicit = channel["explicit"].string == "yes"
        newFeed.generator = channel["generator"].string
        newFeed.language = channel["language"].string
        newFeed.lastBuildDate = dateFormatter.dateFromString(channel["lastBuildDate"].string ?? "")
        newFeed.pubDate = dateFormatter.dateFromString(channel["pubDate"].string ?? "")
        newFeed.subtitle = channel["itunes:subtitle"].string
        newFeed.summary = channel["itunes:summary"].string
        newFeed.title = channel["title"].string
        feed = newFeed

        return feed
    }

    func parseImage(xmlData: NSData) throws -> FeedImage? {
        var feedImage: FeedImage?
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        if let
            imageUrlString = channel["itunes:image"].attributes["href"],
            url = NSURL(string: imageUrlString)
        {
            feedImage = FeedImage(url: url)
        }

        return feedImage
    }

    func parseEpisodes(xmlData: NSData) throws -> [FeedEpisode]? {
        var feedEpisodes: [FeedEpisode]?
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        guard let items = channel["item"].all else { return [] }

        feedEpisodes = [FeedEpisode]()
        for item in items {
            var episode = FeedEpisode()
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
                    episode.image = FeedImage(url: episodeImageUrl)
//                }
            }

            let enclosure = item["enclosure"]
            var audioFile = FeedAudioFile()
            audioFile.length = enclosure.attributes["length"] ?? ""
            audioFile.type = enclosure.attributes["type"] ?? ""
            audioFile.url = enclosure.attributes["url"] ?? ""
            episode.audioFile = audioFile

            feedEpisodes!.append(episode)
//                delegate?.feedParser(self, didFinishWithEpisode: episode)
        }

        return feedEpisodes
    }
}