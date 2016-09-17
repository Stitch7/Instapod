//
//  FeedUpdater.swift
//  Instapod
//
//  Created by Christopher Reitz on 08.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

class FeedUpdater: FeedOperationDelegate, ImageOperationDelegate {

    // MARK: - Properties

    var podcasts = [String: Podcast]()
    var delegates = MulticastDelegate<FeedUpdaterDelegate>()

    fileprivate var operationsCount = 0
    fileprivate var foundEpisodesCount = 0
    fileprivate var parserErrors = [String: Error]()

    fileprivate var _queue: OperationQueue?
    fileprivate var queue: OperationQueue {
        if let queue = _queue { return queue }

        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 20
        _queue = queue
        return queue
    }

    // MARK: - Initializer

    init(podcasts: [Podcast]) {
        for podcast in podcasts {
            self.podcasts[podcast.uuid] = podcast
        }
    }

    // MARK: - Public

    func update() {
        guard podcasts.count > 0 else {
            self.delegates.invoke {
                $0.feedUpdater(self, didFinishWithNumberOfEpisodes: 0)
            }
            return
        }

        let aexmlParser = FeedParserAEXML()
        for (uuid, podcast) in podcasts {
            let operation = FeedOperation(uuid: uuid, url: podcast.url, parser: aexmlParser)
            operation.delegate = self
            queue.addOperation(operation)
            operationsCount += 1
        }
    }

    // MARK: - FeedOperationDelegate

    func feedOperation(_ feedOperation: FeedOperation, didFinishWithPodcast podcast: Podcast) {
        defer {
            finishEventually()
        }

        let new = podcast
        guard let
            old = podcasts[new.uuid],
            let newEpisodes = new.episodes,
            let oldEpisodes = old.episodes
        else { return }

        guard oldEpisodes.count != newEpisodes.count else { return }

        for newEpisode in newEpisodes {
            let found = oldEpisodes.filter { $0.title == newEpisode.title }
            guard found.count == 0 else { continue }

            print("🤗 FOUND A NEW EPISODE 👉 \(new.title!) - \(newEpisode.title!)")
            foundEpisodesCount += 1
            importImage(podcast: new, episode: newEpisode)
        }
    }

    func importImage(podcast: Podcast, episode: Episode?) {
        guard let episode = episode else { return }
        guard let image = episode.image else {
            DispatchQueue.main.async {
                self.delegates.invoke {
                    $0.feedUpdater(self, didFinishWithEpisode: episode, ofPodcast: podcast)
                }
            }
            return
        }

        let session = URLSession.shared
        let imageOperation = ImageOperation(image: image,
                                            session: session,
                                            podcast: podcast,
                                            episode: episode)
        imageOperation.delegate = self

        queue.addOperation(imageOperation)
        operationsCount += 1
    }


    func feedOperation(_ feedOperation: FeedOperation, didFinishWithEpisode episode: Episode) {
    }

    func feedOperation(_ feedOperation: FeedOperation, didFinishWithError error: Error?) {
        if let err = error {
            parserErrors[feedOperation.url.absoluteString] = err
        }

        finishEventually()
    }

    // MARK: - ImageOperationDelegate

    func imageOperation(_ imageOperation: ImageOperation, didFinishWithImage image: Image, ofPodcast podcast: Podcast, episode: Episode?) {
        guard let episode = episode else { return }
        DispatchQueue.main.async {
            print("🖼✅: \(image.url.absoluteString)")
//            episode.image = image
            self.delegates.invoke {
                $0.feedUpdater(self, didFinishWithEpisode: episode, ofPodcast: podcast)
            }
        }
        self.finishEventually()
    }

    func imageOperation(_ imageOperation: ImageOperation, didFinishWithError error: Error?) {
        if let err = error {
            parserErrors[imageOperation.image.url.absoluteString] = err
        }
        
        finishEventually()
    }

    fileprivate func finishEventually() {
        DispatchQueue.main.async {
            self.operationsCount -= 1
            if self.operationsCount <= 0 {
                self.delegates.invoke {
                    $0.feedUpdater(self, didFinishWithNumberOfEpisodes: self.foundEpisodesCount)
                }
                self.printSummary()
            }
        }
    }

    fileprivate func printSummary() {
        print("👌👌👌👌👌 ALL FEEDS PARSED 👌👌👌👌👌")
        if parserErrors.count > 0 {
            for error in parserErrors {
                print(error)
            }
        }
    }
}
