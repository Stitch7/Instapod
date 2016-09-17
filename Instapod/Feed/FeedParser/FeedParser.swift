//
//  FeedParser.swift
//  Instapod
//
//  Created by Christopher Reitz on 18.06.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

protocol FeedParser {
    func nextPage(_ xmlData: Data) throws -> URL?
    func parseFeed(uuid: String, url: URL, xmlData: Data) throws -> Podcast
    func parseImage(_ xmlData: Data) throws -> Image?
    func parseEpisodes(_ xmlData: Data) throws -> [Episode]?
}
