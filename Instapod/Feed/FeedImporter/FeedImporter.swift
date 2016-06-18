//
//  FeedImporter.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation
import AEXML

class FeedImporter: FeedOperationDelegate, ImageOperationDelegate {

    // MARK: - Properties

    var delegate: FeedImporterDelegate?

    private var operationsCount = 0
    private var parserErrors = [String: ErrorType]()

    private var queue: NSOperationQueue {
        let queue = NSOperationQueue()
        queue.qualityOfService = .UserInitiated
        queue.maxConcurrentOperationCount = 5
        return queue
    }

    var favs = [String]()

    // MARK: - Initializer

    init() {
        let path = NSBundle.mainBundle().pathForResource("subscriptions", ofType: "opml")
        let data = try! NSData(contentsOfFile: path!, options: .DataReadingMappedIfSafe)
        let xml = try! AEXMLDocument(xmlData: data)

        if let outlines = xml.root["body"]["outline"].all {
            for outline in outlines {
                guard let url = outline.attributes["xmlUrl"] else { continue }
                favs.append(url)
            }
        }
    }

    func start() {
        for fav in favs {
            guard let url = NSURL(string: fav) else { continue }

            let operation = FeedOperation(feed: Feed(url: url), url: url, session: NSURLSession.sharedSession())
            operation.delegate = self
            operationsCount += 1
            queue.addOperation(operation)
        }
    }

    // MARK: - FeedOperationDelegate

    func feedOperation(feedOperation: FeedOperation, didFinishWithFeed feed: Feed) {
        if let nextPage = feed.nextPage {
            let nextPageOperation = FeedOperation(feed: feed, url: nextPage, session: NSURLSession.sharedSession())
            nextPageOperation.delegate = self
            queue.addOperation(nextPageOperation)
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            print("📦✅: \(feed.url)")
            self.importImage(feed: feed, episode: nil)

            if let feedEpisodes = feed.episodes {
                for feedEpisode in feedEpisodes {
                    self.importImage(feed: feed, episode: feedEpisode)
                }
            }

            self.finishEventually()
        }
    }

    func feedOperation(feedOperation: FeedOperation, didFinishWithEpisode episode: FeedEpisode) {
    }

    // MARK: - ImageOperationDelegate

    func importImage(feed feed: Feed, episode: FeedEpisode?) {

        var image: FeedImage?
        if let episode = episode {
            if let episodeImage = episode.image {
                image = episodeImage
            }
        }
        else {
            image = feed.image
        }

        guard let img = image else { return }

        let imageOperation = ImageOperation(image: img, session: NSURLSession.sharedSession(), feed: feed, episode: episode)
        imageOperation.delegate = self

        queue.addOperation(imageOperation)
        operationsCount += 1
    }

    func feedOperation(feedOperation: FeedOperation, didFinishWithError error: ErrorType?) {
        if let err = error {
            parserErrors[feedOperation.feed.url.absoluteString] = err
        }

        finishEventually()
    }

    func imageOperation(imageOperation: ImageOperation, didFinishWithImage image: FeedImage, ofFeed feed: Feed, episode: FeedEpisode?) {
        dispatch_async(dispatch_get_main_queue()) {
            print("🖼✅: \(image.url.absoluteString)")

            if let episode = episode {
                episode.image = image
            } else {
                feed.image = image
            }

            if feed.allImagesAreFetched {
                self.delegate?.feedImporter(self, didFinishWithFeed: feed)
            }

            self.finishEventually()
        }
    }

    func imageOperation(imageOperation: ImageOperation, didFinishWithError error: ErrorType?) {
        if let err = error {
            parserErrors[imageOperation.image.url.absoluteString] = err
        }

        finishEventually()
    }

    private func finishEventually() {
        operationsCount -= 1
        if 0 >= operationsCount {
            delegate?.feedImporterDidFinishWithAllFeeds(self)
            printSummary()
        }
    }

    private func printSummary() {
        print("👌👌👌👌👌 ALL FEEDS PARSED 👌👌👌👌👌")
        if parserErrors.count > 0 {
            print("💣💣💣 AEXMLDocument Error:")
            for (urlString, error) in parserErrors {
                print(urlString)
                print(error)
            }
        }
    }
}
