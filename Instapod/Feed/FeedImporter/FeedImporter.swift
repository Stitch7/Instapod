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
    var delegates = MulticastDelegate<FeedImporterDelegate>()
    var podcasts = [String: Podcast]()

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
        _ = datasource.urls?.map { createFeedOperation(uuid: NSUUID().UUIDString, url: $0) }
    }

    func createFeedOperation(uuid uuid: String, url: NSURL) {
        let operation = FeedOperation(uuid: uuid, url: url, parser: FeedParserAEXML())
        operation.delegate = self
        operationsCount += 1
        queue.addOperation(operation)
    }

    func createImageOperation(image image: Image?, podcast: Podcast, episode: Episode? = nil) {
        guard let img = image else { return }

        let imageOperation = ImageOperation(image: img,
                                            session: NSURLSession.sharedSession(),
                                            podcast: podcast,
                                            episode: episode)
        imageOperation.delegate = self

        queue.addOperation(imageOperation)
        operationsCount += 1
    }
    
    // MARK: - FeedOperationDelegate

    func feedOperation(feedOperation: FeedOperation, didFinishWithPodcast podcast: Podcast) {
        if podcasts[podcast.uuid] != nil {
            if let newEpisodes = podcast.episodes {
                for episode in newEpisodes {
                    self.podcasts[podcast.uuid]!.episodes?.append(episode)
                }
            }
        }
        else {
            podcasts[podcast.uuid] = podcast
        }

        if let nextPage = podcast.nextPage {
            operationsCount -= 1
            createFeedOperation(uuid: podcast.uuid, url: nextPage)
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            print("📦✅: \(podcast.url)")
            self.createImageOperation(image: podcast.image,
                                      podcast: self.podcasts[podcast.uuid]!)

            if let feedEpisodes = self.podcasts[podcast.uuid]!.episodes {
                for feedEpisode in feedEpisodes {
                    guard feedEpisode.image?.url != podcast.image?.url else { continue }
                    self.createImageOperation(image: feedEpisode.image,
                                              podcast: podcast,
                                              episode: feedEpisode)
                }
            }

            self.finishEventually()
        }
    }

    // MARK: - ImageOperationDelegate

    func feedOperation(feedOperation: FeedOperation, didFinishWithError error: ErrorType?) {
        if let err = error {
            print("💣💣💣 Feed Parser Error:")
            print(feedOperation.url)
            print(err)
            print("---")
        }

        finishEventually()
    }

    func imageOperation(imageOperation: ImageOperation, didFinishWithImage image: Image, ofPodcast podcast: Podcast, episode: Episode?) {
        dispatch_async(dispatch_get_main_queue()) {
            print("🖼✅: \(image.url.absoluteString)")
            guard self.podcasts[podcast.uuid] != nil else { return }

            if let episode = episode {
                self.podcasts[podcast.uuid]!.updateEpisode(with: episode)
            }
            else {
                self.podcasts[podcast.uuid]!.image = image
            }

            if self.podcasts[podcast.uuid]!.allImagesAreFetched {
                self.delegates.invoke {
                    $0.feedImporter(self, didFinishWithFeed: self.podcasts[podcast.uuid]!)
                }
                self.podcasts.removeValueForKey(podcast.uuid)
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
            delegates.invoke {
                $0.feedImporterDidFinishWithAllFeeds(self)
            }
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
