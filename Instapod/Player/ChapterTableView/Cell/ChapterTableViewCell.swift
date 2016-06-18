//
//  ChapterTableViewCell.swift
//  Instapod
//
//  Created by Christopher Reitz on 09.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class ChapterTableViewCell: UITableViewCell {

    // MARK: - IB Outlets

    @IBOutlet weak var noLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    // MARK: - Initializers

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        initialize()
    }

    func initialize() {
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        noLabel.textAlignment = .Right
        noLabel.textColor = UIColor.grayColor()

        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.darkGrayColor()

        timeLabel.textAlignment = .Right
        timeLabel.textColor = UIColor.grayColor()
    }
}
