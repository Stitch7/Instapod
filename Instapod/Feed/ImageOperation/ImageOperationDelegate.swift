//
//  ImageOperationDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 09.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

protocol ImageOperationDelegate: class {
    func imageOperation(imageOperation: ImageOperation, didFinishWithImage image: Image, ofFeed feed: Podcast, episode: Episode?)
    func imageOperation(imageOperation: ImageOperation, didFinishWithError error: ErrorType?)
}
