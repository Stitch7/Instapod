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
        separatorInset = UIEdgeInsets.zero
        layoutMargins = UIEdgeInsets.zero
        preservesSuperviewLayoutMargins = false
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        noLabel.textAlignment = .right
        noLabel.textColor = UIColor.gray

        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.darkGray

        timeLabel.textAlignment = .right
        timeLabel.textColor = UIColor.gray
    }
}
