//
//  FeedParser.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.06.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

protocol FeedParser {
    func nextPage(xmlData: NSData) throws -> NSURL?
    func parseFeed(url url: NSURL, xmlData: NSData) throws -> Feed
    func parseImage(xmlData: NSData) throws -> FeedImage?
    func parseEpisodes(xmlData: NSData) throws -> [FeedEpisode]?
}
