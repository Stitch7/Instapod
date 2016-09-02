//
//  FeedImporter.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

class FeedImporter: FeedOperationDelegate, ImageOperationDelegate {

    // MARK: - Properties

    var datasource: FeedImporterDatasource
    var delegate: FeedImporterDelegate?
    var feeds = [String: Feed]()

    private var operationsCount = 0
    private var parserErrors = [String: ErrorType]()

    private var _queue: NSOperationQueue?
    private var queue: NSOperationQueue {
        if let queue = _queue { return queue }

        let queue = NSOperationQueue()
        queue.qualityOfService = .UserInitiated
        queue.maxConcurrentOperationCount = 5
        _queue = queue
        return queue
    }

    // MARK: - Initializer

    init(datasource: FeedImporterDatasource) {
        self.datasource = datasource
    }

    func start() {
        let
        _ = datasource.urls?.map { createFeedOperation(uuid: NSUUID().UUIDString, url: $0) }
    }

    func createFeedOperation(uuid uuid: String, url: NSURL) {
        let operation = FeedOperation(uuid: uuid, url: url, parser: FeedParserAEXML())
        operation.delegate = self
        operationsCount += 1
        queue.addOperation(operation)
    }

    func createImageOperation(image image: FeedImage?, feed: Feed, episode: FeedEpisode?) {
        guard let img = image else { return }

        let imageOperation = ImageOperation(image: img,
                                            session: NSURLSession.sharedSession(),
                                            feed: feed,
                                            episode: episode)
        imageOperation.delegate = self

        queue.addOperation(imageOperation)
        operationsCount += 1
    }
    
    // MARK: - FeedOperationDelegate

    func feedOperation(feedOperation: FeedOperation, didFinishWithFeed feed: Feed) {
        if feeds[feed.uuid] != nil {
            if let newEpisodes = feed.episodes {
                for episode in newEpisodes {
                    self.feeds[feed.uuid]!.episodes?.append(episode)
                }
            }
        }
        else {
            print(feed.uuid)
            feeds[feed.uuid] = feed
        }

        if let nextPage = feed.nextPage {
            operationsCount -= 1
            createFeedOperation(uuid: feed.uuid, url: nextPage)
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            print("📦✅: \(feed.url)")
            self.createImageOperation(image: feed.image, feed: self.feeds[feed.uuid]!, episode: nil)

            if let feedEpisodes = self.feeds[feed.uuid]!.episodes {
                for feedEpisode in feedEpisodes {
                    self.createImageOperation(image: feedEpisode.image,
                                              feed: feed,
                                              episode: feedEpisode)
                }
            }

            self.finishEventually()
        }
    }

    // MARK: - ImageOperationDelegate

    func feedOperation(feedOperation: FeedOperation, didFinishWithError error: ErrorType?) {
        if let error = error {
            print("💣💣💣 Feed Parser Error:")
            print(feedOperation.url)
            print(error)
            print("---")
        }

        finishEventually()
    }

    func imageOperation(imageOperation: ImageOperation, didFinishWithImage image: FeedImage, ofFeed feed: Feed, episode: FeedEpisode?) {
        dispatch_async(dispatch_get_main_queue()) {
            print("🖼✅: \(image.url.absoluteString)")

            if let episode = episode {
                self.feeds[feed.uuid]?.updateEpisode(with: episode)
            }
            else {
                self.feeds[feed.uuid]!.image = image
            }

            if self.feeds[feed.uuid]!.allImagesAreFetched {
                self.delegate?.feedImporter(self, didFinishWithFeed: self.feeds[feed.uuid]!)
            }

            self.finishEventually()
        }
    }

    func imageOperation(imageOperation: ImageOperation, didFinishWithError error: ErrorType?) {
        if let err = error {
            let key = imageOperation.image.url.absoluteString
            parserErrors[key] = err
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
                print(urlString, error)
            }
        }
    }
}
