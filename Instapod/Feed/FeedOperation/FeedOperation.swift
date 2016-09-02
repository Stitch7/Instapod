//
//  FeedOperation.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class FeedOperation: AsynchronousOperation {

    // MARK: - Properties

    let uuid: String
    var url: NSURL
    var parser: FeedParser
    var task: NSURLSessionTask!
    var delegate: FeedOperationDelegate?
    var session = NSURLSession.sharedSession()

    // MARK: - Initializer

    init(uuid: String, url: NSURL, parser: FeedParser) {
        self.uuid = uuid
        self.parser = parser
        self.url = url
        super.init()
        configureTask()
    }

    private func configureTask() {
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

            do {
                let parser = strongSelf.parser
                var feed = try parser.parseFeed(uuid: strongSelf.uuid, url: strongSelf.url, xmlData: xmlData)
                feed.nextPage = try parser.nextPage(xmlData)
                feed.image = try parser.parseImage(xmlData)
                feed.episodes = try parser.parseEpisodes(xmlData)
                strongSelf.delegate?.feedOperation(strongSelf, didFinishWithFeed: feed)
            } catch {
                strongSelf.delegate?.feedOperation(strongSelf, didFinishWithError: error)
            }
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
}
