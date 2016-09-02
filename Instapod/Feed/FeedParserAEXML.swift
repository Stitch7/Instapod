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

    func parseFeed(uuid uuid: String, url: NSURL, xmlData: NSData) throws -> Feed {
        let xmlDocument = try AEXMLDocument(xmlData: xmlData)
        let channel = xmlDocument.root["channel"]

        var feed = Feed(uuid: uuid, url: url)
        feed.author = channel["itunes:author"].string
        feed.category = channel["itunes:category"].string
        feed.desc = channel["description"].string
        feed.explicit = channel["explicit"].string == "yes"
        feed.generator = channel["generator"].string
        feed.language = channel["language"].string
        feed.lastBuildDate = dateFormatter.dateFromString(channel["lastBuildDate"].string ?? "")
        feed.pubDate = dateFormatter.dateFromString(channel["pubDate"].string ?? "")
        feed.subtitle = channel["itunes:subtitle"].string
        feed.summary = channel["itunes:summary"].string
        feed.title = channel["title"].string

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