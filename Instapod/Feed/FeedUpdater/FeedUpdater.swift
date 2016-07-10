////
////  FeedUpdater.swift
////  Instapod
////
////  Created by Christopher Reitz on 08.04.16.
////  Copyright © 2016 Christopher Reitz. All rights reserved.
////
//
import Foundation

class FeedUpdater {
//: FeedOperationDelegate, ImageOperationDelegate {

    // MARK: - Properties

    var podcasts: [Podcast]
    var delegate: FeedUpdaterDelegate?
//
//    private let session = NSURLSession.sharedSession()
//
//    private var operationsCount = 0
//    private var foundEpisodesCount = 0
//    private var parserErrors = [String: ErrorType]()
//
//    private var _queue: NSOperationQueue?
//    private var queue: NSOperationQueue {
//        if let queue = _queue { return queue }
//
//        let queue = NSOperationQueue()
//        queue.qualityOfService = .UserInitiated
//        queue.maxConcurrentOperationCount = 20
//        _queue = queue
//        return queue
//    }

    // MARK: - Initializer

    init(podcasts: [Podcast]) {
        self.podcasts = podcasts
    }
//
    // MARK: - Public

    func update() {
        print("TODO")
//        guard podcasts.count > 0 else {
//            self.delegate?.feedUpdater(self, didFinishWithNumberOfEpisodes: 0)
//            return
//        }
//
//        for podcast in podcasts {
//            guard let urlString = podcast.url else { continue }
//            guard let url = NSURL(string: urlString) else { continue }
//
//            let feed = Feed(url: url)
//            let operation = FeedOperation(feed: feed, url: url, session: session)
//            operation.delegate = self
//            queue.addOperation(operation)
//            operationsCount += 1
//        }
    }
//
//    // MARK: - FeedOperationDelegate
//
//    func feedOperation(feedOperation: FeedOperation, didFinishWithFeed feed: Feed) {
//        defer {
//            finishEventually()
//        }
//        var podcast: Podcast!
//        for toCompare in podcasts {
//            guard let titleToCompare = toCompare.title else { continue }
//
//            if feed.title == titleToCompare {
//                podcast = toCompare
//            }
//        }
//
//        guard podcast != nil else { return }
//        guard let podcastEpisodes = podcast.episodes?.allObjects as? [Episode] else { return }
//        guard let feedEpisodes = feed.episodes else { return }
//        guard podcastEpisodes.count != feedEpisodes.count else { return }
//
//        for foundEpisode in feedEpisodes {
//            let found = podcastEpisodes.filter { $0.title == foundEpisode.title }
//            guard found.count == 0 else { continue }
//
//            print("🤗 FOUND A NEW EPISODE \(feed.title!) \(foundEpisode.title!)")
//            foundEpisodesCount += 1
//            importImage(feed: feed, episode: foundEpisode)
//        }
//    }
//
//    func feedOperation(feedOperation: FeedOperation, didFinishWithEpisode episode: FeedEpisode) {
//    }
//
//    func feedOperation(feedOperation: FeedOperation, didFinishWithError error: ErrorType?) {
//        if let err = error {
//            parserErrors[feedOperation.feed.url.absoluteString] = err
//        }
//
//        finishEventually()
//    }
//
//    // MARK: - FeedOperationDelegate
//
//    func importImage(feed feed: Feed, episode: FeedEpisode?) {
//        guard let episode = episode else { return }
//        guard let image = episode.image else {
//            delegate?.feedUpdater(self, didFinishWithEpisode: episode, ofFeed: feed)
//            return
//        }
//
//        let imageOperation = ImageOperation(image: image, session: session, feed: feed, episode: episode)
//        imageOperation.delegate = self
//
//        queue.addOperation(imageOperation)
//        operationsCount += 1
//    }
//
//    // MARK: - ImageOperationDelegate
//
//    func imageOperation(imageOperation: ImageOperation, didFinishWithImage image: FeedImage, ofFeed feed: Feed, episode: FeedEpisode?) {
//        guard let episode = episode else { return }
//        dispatch_async(dispatch_get_main_queue()) {
//            print("🖼✅: \(image.url.absoluteString)")
//            episode.image = image
//            self.delegate?.feedUpdater(self, didFinishWithEpisode: episode, ofFeed: feed)
//            self.finishEventually()
//        }
//    }
//
//    func imageOperation(imageOperation: ImageOperation, didFinishWithError error: ErrorType?) {
//        if let err = error {
//            parserErrors[imageOperation.image.url.absoluteString] = err
//        }
//        
//        finishEventually()
//    }
//
//    private func finishEventually() {
//        operationsCount -= 1
//        if 0 >= operationsCount {
//            delegate?.feedUpdater(self, didFinishWithNumberOfEpisodes: foundEpisodesCount)
//            printSummary()
//        }
//    }
//
//    private func printSummary() {
//        print("👌👌👌👌👌 ALL FEEDS PARSED 👌👌👌👌👌")
//        if parserErrors.count > 0 {
//            for error in parserErrors {
//                print(error)
//            }
//        }
//    }
}
