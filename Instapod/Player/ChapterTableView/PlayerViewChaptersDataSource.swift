//
//  PlayerViewChaptersDataSource.swift
//  Instapod
//
//  Created by Christopher Reitz on 24.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import AVFoundation

@objc
class ChapterTableViewDataSource: NSObject, UITableViewDataSource {

    // MARK: - Properties

    let chapters: [AVTimedMetadataGroup]
    let multilineParagraphStyle: NSMutableParagraphStyle

    // MARK: - Initializers

    required init(chapters: [AVTimedMetadataGroup]) {
        self.chapters = chapters
        self.multilineParagraphStyle = NSMutableParagraphStyle()
        self.multilineParagraphStyle.hyphenationFactor = 1.0
    }

    // MARK: - UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chapters.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChapterCell", forIndexPath: indexPath) as! ChapterTableViewCell
        let chapter = chapters[indexPath.row]

        var titleWithHyphens = NSAttributedString()
        if let title = chapter.items.first?.value {
            titleWithHyphens = NSMutableAttributedString(
                string: String(title),
                attributes: [NSParagraphStyleAttributeName: multilineParagraphStyle]
            )
        }

        cell.noLabel?.text = "\(indexPath.row + 1)."
        cell.titleLabel?.attributedText = titleWithHyphens
        cell.timeLabel?.text = chapter.timeRange.duration.shortStringValue
        cell.separatorInset = UIEdgeInsetsZero

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if self.tableView(tableView, numberOfRowsInSection: section) == 0 { return nil }
        return "Chapters" // TODO: i18n
    }
}
