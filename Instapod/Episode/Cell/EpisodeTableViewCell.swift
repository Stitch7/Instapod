//
//  EpisodeTableViewCell.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class EpisodeTableViewCell: UITableViewCell {

    // MARK: - IB Outlets

    @IBOutlet weak var hearedView: CircleView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var pubDateLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!

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

        backgroundColor = ColorPalette.TableView.Cell.Background

        titleLabel.numberOfLines = 0
        titleLabel.textColor = UIColor.darkGray

        summaryLabel.numberOfLines = 0
        summaryLabel.textColor = UIColor.gray

        pubDateLabel.textColor = UIColor.gray
        durationLabel.textColor = UIColor.gray
    }
}
