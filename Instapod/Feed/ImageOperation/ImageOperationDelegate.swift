//
//  ImageOperationDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 09.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

protocol ImageOperationDelegate: class {
    func imageOperation(_ imageOperation: ImageOperation, didFinishWithImage image: Image, ofPodcast podcast: Podcast, episode: Episode?)
    func imageOperation(_ imageOperation: ImageOperation, didFinishWithError error: Error?)
}
