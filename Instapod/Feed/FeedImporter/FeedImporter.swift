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

    fileprivate var operationsCount = 0
    fileprivate var parserErrors = [String: Error]()

    fileprivate var _queue: OperationQueue?
    fileprivate var queue: OperationQueue {
        if let queue = _queue { return queue }

        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 5
        _queue = queue
        return queue
    }

    // MARK: - Initializer

    init(datasource: FeedImporterDatasource) {
        self.datasource = datasource
    }

    func start() {
        _ = datasource.urls?.map { createFeedOperation(uuid: UUID().uuidString, url: $0 as URL) }
    }

    func createFeedOperation(uuid: String, url: URL) {
        let operation = FeedOperation(uuid: uuid, url: url, parser: FeedParserAEXML())
        operation.delegate = self
        operationsCount += 1
        queue.addOperation(operation)
    }

    func createImageOperation(image: Image?, podcast: Podcast, episode: Episode? = nil) {
        guard let img = image else { return }

        let imageOperation = ImageOperation(image: img,
                                            session: URLSession.shared,
                                            podcast: podcast,
                                            episode: episode)
        imageOperation.delegate = self

        queue.addOperation(imageOperation)
        operationsCount += 1
    }
    
    // MARK: - FeedOperationDelegate

    func feedOperation(_ feedOperation: FeedOperation, didFinishWithPodcast podcast: Podcast) {
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
            createFeedOperation(uuid: podcast.uuid, url: nextPage as URL)
            return
        }

        DispatchQueue.main.async {
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

    func feedOperation(_ feedOperation: FeedOperation, didFinishWithError error: Error?) {
        if let err = error {
            print("💣💣💣 Feed Parser Error:")
            print(feedOperation.url)
            print(err)
            print("---")
        }

        finishEventually()
    }

    func imageOperation(_ imageOperation: ImageOperation, didFinishWithImage image: Image, ofPodcast podcast: Podcast, episode: Episode?) {
        DispatchQueue.main.async {
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
                self.podcasts.removeValue(forKey: podcast.uuid)
            }

            self.finishEventually()
        }
    }

    func imageOperation(_ imageOperation: ImageOperation, didFinishWithError error: Error?) {
        if let err = error {
            let key = imageOperation.image.url.absoluteString
            parserErrors[key] = err
        }

        finishEventually()
    }

    fileprivate func finishEventually() {
        operationsCount -= 1
        if 0 >= operationsCount {
            delegates.invoke {
                $0.feedImporterDidFinishWithAllFeeds(self)
            }
            printSummary()
        }
    }

    fileprivate func printSummary() {
        print("👌👌👌👌👌 ALL FEEDS PARSED 👌👌👌👌👌")
        if parserErrors.count > 0 {
            print("💣💣💣 AEXMLDocument Error:")
            for (urlString, error) in parserErrors {
                print(urlString, error)
            }
        }
    }
}
