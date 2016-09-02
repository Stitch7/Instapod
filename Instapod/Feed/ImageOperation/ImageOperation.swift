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
    var feed: Podcast
    var episode: Episode?
    var delegate: ImageOperationDelegate?

    // MARK: - Initializer

    init(image: Image, session: NSURLSession, feed: Podcast, episode: Episode?) {
        self.image = image
        self.feed = feed
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

            if let thumbnail56 = strongSelf.createThumbnail(image: tempImage, size: 56.0) {
                strongSelf.image.thumbnail56 = thumbnail56
                strongSelf.image.thumbnail72 = strongSelf.createThumbnail(image: tempImage, size: 72.0)
                strongSelf.image.color = strongSelf.extractColors(image: UIImage(data: thumbnail56)!)
            }

            strongSelf.image.isFetched = true

            if strongSelf.episode != nil {
                strongSelf.episode!.image = strongSelf.image
                strongSelf.feed.updateEpisode(with: strongSelf.episode!)
            }
            else {
                strongSelf.feed.image = strongSelf.image
            }

            strongSelf.delegate?.imageOperation(strongSelf,
                                                didFinishWithImage: strongSelf.image,
                                                ofFeed: strongSelf.feed,
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

    // MARK: - Fetching

    private func createThumbnail(image image: UIImage, size baseSize: CGFloat) -> NSData? {
        let length = UIScreen.mainScreen().scale * baseSize
        let size = CGSizeMake(length, length)

        UIGraphicsBeginImageContext(size)
        image.drawInRect(CGRectMake(0.0, 0.0, size.width, size.height))
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()

        var thumbnailData: NSData?
        if let png = UIImagePNGRepresentation(thumbnailImage) {
            thumbnailData = NSData(data: png)
        }
        else if let jpeg = UIImageJPEGRepresentation(thumbnailImage, 1.0) {
            thumbnailData = NSData(data: jpeg)
        }
        UIGraphicsEndImageContext()

        return thumbnailData
    }

    private func extractColors(image image: UIImage) -> UIColor {
        var color = UIColor.blackColor()

        let cube = ColorCube()
        let imageColors = cube.extractColorsFromImage(image, flags: [.AvoidWhite, .AvoidBlack])
        if let mainColor = imageColors.first {
            color = mainColor
        }

        return color
    }
}
