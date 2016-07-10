//
//  FeedParserAEXMLTests.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.07.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import XCTest
@testable import Instapod

class FeedParserAEXMLTests: XCTestCase {

    // MARK: - Helper

    let parser: FeedParser = FeedParserAEXML()
    var feed: Feed?
    var feedData: NSData!

    // MARK: - XCTestCase

    override func setUp() {
        super.setUp()

        setUpFeed()
    }

    private func setUpFeed() {
        do {
            let url = NSURL(string: "http://cre.fm/feed/m4a")!
            let bundle = NSBundle(forClass: self.dynamicType)
            let path = bundle.pathForResource("cre", ofType: "xml")
            feedData = try NSData(contentsOfFile: path!, options: .DataReadingMappedIfSafe)
            feed = try parser.parseFeed(url: url, xmlData: feedData)
        }
        catch {
            print(error)
        }
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Tests

    func testParseFeed() {
        XCTAssertNotNil(self.feed)
        if let feed = self.feed {
            XCTAssertNotNil(feed.url)
            XCTAssertNotNil(feed.author)
            XCTAssertNotNil(feed.category)
            XCTAssertNotNil(feed.desc)
            XCTAssertNotNil(feed.explicit)
            XCTAssertNotNil(feed.generator)
            XCTAssertNotNil(feed.language)
            XCTAssertNotNil(feed.lastBuildDate)
//            XCTAssertNotNil(feed?.pubDate)
            XCTAssertNotNil(feed.subtitle)
            XCTAssertNotNil(feed.summary)
            XCTAssertNotNil(feed.title)
        }
    }

    func testParseImage() {
        do {
            feed?.image = try parser.parseImage(feedData)
        }
        catch {
            print(error)
        }

        XCTAssertNotNil(feed?.image)
        XCTAssertNotNil(feed?.image?.url)
    }

    func testParseEpisodes() {
        do {
            feed?.episodes = try parser.parseEpisodes(feedData)
        }
        catch {
            print(error)
        }

        XCTAssertNotNil(feed?.episodes)
        XCTAssertEqual(feed?.episodes?.count, 60)
    }

    func testNextPage() {
        let nextPageUrl = try? parser.nextPage(feedData)

        XCTAssertNotNil(nextPageUrl)
    }
}
