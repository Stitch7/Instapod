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
    var url: URL
    var parser: FeedParser
    var task: URLSessionTask!
    var delegate: FeedOperationDelegate?
    var session = URLSession.shared

    // MARK: - Initializer

    init(uuid: String, url: URL, parser: FeedParser) {
        self.uuid = uuid
        self.parser = parser
        self.url = url
        super.init()
        configureTask()
    }

    fileprivate func configureTask() {
        task = session.dataTask(with: url, completionHandler: { [weak self] (data, response, error) in
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
                var podcast = try parser.parseFeed(uuid: strongSelf.uuid,
                                                   url: strongSelf.url,
                                                   xmlData: xmlData)
                podcast.nextPage = try parser.nextPage(xmlData)
                podcast.image = try parser.parseImage(xmlData)
                podcast.episodes = try parser.parseEpisodes(xmlData)
                strongSelf.delegate?.feedOperation(strongSelf, didFinishWithPodcast: podcast)
            } catch {
                strongSelf.delegate?.feedOperation(strongSelf, didFinishWithError: error)
            }
        }) 
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
