//
//  FeedOperationDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 02.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

protocol FeedOperationDelegate: class {
    func feedOperation(feedOperation: FeedOperation, didFinishWithFeed feed: Feed)
    func feedOperation(feedOperation: FeedOperation, didFinishWithError error: ErrorType?)
}
