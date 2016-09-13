//
//  ImageOperation.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class ImageOperation: AsynchronousOperation {

    // MARK: - Properties

    var image: Image
    var task: NSURLSessionTask!
    var podcast: Podcast
    var episode: Episode?
    var delegate: ImageOperationDelegate?

    // MARK: - Initializer

    init(image: Image, session: NSURLSession, podcast: Podcast, episode: Episode?) {
        self.image = image
        self.podcast = podcast
        self.episode = episode

        super.init()

        task = session.dataTaskWithURL(image.url) { [weak self] (data, response, error) in
            guard let strongSelf = self else { return }

            defer {
                strongSelf.completeOperation()
            }

            if let requestError = error {
                strongSelf.delegate?.imageOperation(strongSelf, didFinishWithError: requestError)
                return
            }
            guard let imageData = data else {
                let domain = NSBundle.mainBundle().bundleIdentifier!
                let error = NSError(domain: domain,
                                    code: 23,
                                    userInfo: [NSLocalizedDescriptionKey: "No image data"])
                strongSelf.delegate?.imageOperation(strongSelf, didFinishWithError: error)
                return
            }
            guard let tempImage = UIImage(data: imageData) else {
                let domain = NSBundle.mainBundle().bundleIdentifier!
                let error = NSError(domain: domain,
                                    code: 42,
                                    userInfo: [NSLocalizedDescriptionKey: "Could not generate image"])
                strongSelf.delegate?.imageOperation(strongSelf, didFinishWithError: error)
                return
            }

            strongSelf.image.data = imageData

            if let thumbnail56 = tempImage.createThumbnail(size: 56.0) {
                strongSelf.image.thumbnail56 = thumbnail56
                strongSelf.image.thumbnail72 = tempImage.createThumbnail(size: 72.0)
                strongSelf.image.thumbnail = tempImage.createThumbnail(size: 100.0)
                strongSelf.image.color = thumbnail56.colorCube
            }

            strongSelf.image.isFetched = true

            if strongSelf.episode != nil {
                strongSelf.episode!.image = strongSelf.image
                strongSelf.podcast.updateEpisode(with: strongSelf.episode!)
            }
            else {
                strongSelf.podcast.image = strongSelf.image
            }

            strongSelf.delegate?.imageOperation(strongSelf,
                                                didFinishWithImage: strongSelf.image,
                                                ofPodcast: strongSelf.podcast,
                                                episode: strongSelf.episode)
        }
    }

    // MARK: - NSOperation Entry Point

    override func main() {
        print("🖼⬇️: \(image.url)")        
        task.resume()
    }

    override func cancel() {
        task.cancel()
        super.cancel()
    }
}
