//
//  FeedImporterDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 08.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

protocol FeedImporterDelegate: class {
    func feedImporter(feedImporter: FeedImporter, didFinishWithFeed feed: Podcast)
    func feedImporterDidFinishWithAllFeeds(feedImporter: FeedImporter)
}
