//
//  FeedOperation.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import AEXML 

class FeedOperation: AsynchronousOperation {

    // MARK: - Properties

    var feed: Feed
    var url: NSURL
    var task: NSURLSessionTask!
    var delegate: FeedOperationDelegate?

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

    // MARK: - Initializer

    init(feed: Feed, url: NSURL, session: NSURLSession) {
        self.feed = feed
        self.url = url
        super.init()

        task = session.dataTaskWithURL(url) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }
            
            defer {
                strongSelf.completeOperation()
            }

            if let requestError = error {
                strongSelf.delegate?.feedOperation(strongSelf, didFinishWithError: requestError)
                return
            }
            guard let xmlData = data else {
                strongSelf.delegate?.feedOperation(strongSelf, didFinishWithError: error)
                return
            }

            strongSelf.parseFeed(xmlData: xmlData)
        }
    }

    // MARK: - NSOperation

    override func main() {
        print("📦⬇️: \(url.absoluteString)")
        task.resume()
    }

    override func cancel() {
        task.cancel()
        super.cancel()
    }

    // MARK: - Parsing

    private func parseFeed(xmlData xmlData: NSData) {
        do {
            let xmlDocument = try AEXMLDocument(xmlData: xmlData)
            let channel = xmlDocument.root["channel"]

            extractNextPage(channel)
            if feed.episodes == nil {
                extractFields(channel)
                extractImage(channel)
            }
            feed.episodes = self.parseEpisodes(inChannel: channel)

            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.feedOperation(self, didFinishWithFeed: self.feed)
            }
        } catch {
            handleParseError(error)
        }
    }

    private func extractNextPage(channel: AEXMLElement) {
        feed.nextPage = nil
        guard let links = channel["atom:link"].all else { return }
        for link in links {
            guard link.attributes["rel"] == "next" else { continue }
            if let nextPage = link.attributes["href"] {
                feed.nextPage = NSURL(string: nextPage)
            }
        }
    }

    private func extractFields(channel: AEXMLElement) {
        feed.url = url
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
    }

    private func extractImage(channel: AEXMLElement) {
        if let
            imageUrlString = channel["itunes:image"].attributes["href"],
            url = NSURL(string: imageUrlString)
        {
            self.feed.image = FeedImage(url: url)
        }
    }

    private func handleParseError(error: ErrorType) {
        print("💣💣💣 AEXMLDocument Error:")
        print(error)
        print(feed.url)
        print("---")
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.feedOperation(self, didFinishWithError: error)
        }
    }

    private func parseEpisodes(inChannel channel: AEXMLElement) -> [FeedEpisode] {
        guard let items = channel["item"].all else { return [] }

        var episodes = self.feed.episodes ?? [FeedEpisode]()
        for item in items {
            let episode = FeedEpisode()
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
                if let feedImage = self.feed.image {
                    if feedImage.url.absoluteString != episodeImageUrlString {
                        episode.image = FeedImage(url: episodeImageUrl)
                    }
                }
                else {
                    episode.image = FeedImage(url: episodeImageUrl)
                }
            }

            let enclosure = item["enclosure"]
            let audioFile = FeedAudioFile()
            audioFile.length = enclosure.attributes["length"] ?? ""
            audioFile.type = enclosure.attributes["type"] ?? ""
            audioFile.url = enclosure.attributes["url"] ?? ""
            episode.audioFile = audioFile

            episodes.append(episode)
            delegate?.feedOperation(self, didFinishWithEpisode: episode)
        }

        return episodes
    }
}
