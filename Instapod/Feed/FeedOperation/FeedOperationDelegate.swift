//
//  FeedOperationDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

protocol FeedOperationDelegate: class {
    func feedOperation(_ feedOperation: FeedOperation, didFinishWithPodcast podcast: Podcast)
    func feedOperation(_ feedOperation: FeedOperation, didFinishWithError error: Error?)
}
