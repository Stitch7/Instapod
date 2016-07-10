//
//  FeedImporter.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

class FeedImporter: FeedOperationDelegate, ImageOperationDelegate {


    private var IMGCount = 0


    // MARK: - Properties

    var datasource: FeedImporterDatasource
    var delegate: FeedImporterDelegate?
    var feed: Feed?

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
        _ = datasource.urls?.map{ createFeedOperation(url: $0) }
    }

    func createFeedOperation(url url: NSURL) {
        let operation = FeedOperation(url: url, parser: FeedParserAEXML())
        operation.delegate = self
        operationsCount += 1
        queue.addOperation(operation)
    }

    func createImageOperation(image image: FeedImage?, feed: Feed, episode: FeedEpisode?) {
        guard let img = image else { return }

        let imageOperation = ImageOperation(image: img, session: NSURLSession.sharedSession(), feed: feed, episode: episode)
        imageOperation.delegate = self

        queue.addOperation(imageOperation)
        operationsCount += 1



        IMGCount += 1
    }
    
    // MARK: - FeedOperationDelegate

    func feedOperation(feedOperation: FeedOperation, didFinishWithFeed feed: Feed) {
        if self.feed != nil {
            if let newEpisodes = feed.episodes {
                _ = newEpisodes.map{
                    self.feed?.episodes?.append($0)
                    self.createImageOperation(image: $0.image, feed: feed, episode: $0)
                }
            }
        }
        else {
            self.feed = feed
        }

        if let nextPage = feed.nextPage {
            operationsCount -= 1
            createFeedOperation(url: nextPage)
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            print("📦✅: \(feed.url)")
            self.createImageOperation(image: feed.image, feed: feed, episode: nil)

            if let feedEpisodes = feed.episodes {
                for feedEpisode in feedEpisodes {
                    self.createImageOperation(image: feedEpisode.image, feed: feed, episode: feedEpisode)
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
//                episode.image = image
                self.feed?.updateEpisode(with: episode)
            }
            else {
                self.feed!.image = image
            }

            self.IMGCount -= 1
            if self.IMGCount == 0 {
                let ERGEBNIS = self.feed!.allImagesAreFetched
                print(ERGEBNIS)
            }

            if self.feed!.allImagesAreFetched {
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
                print(urlString, error)
            }
        }
    }
}
