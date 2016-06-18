//
//  PodcastTableViewCell.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {

    // MARK: - IB Outlets

    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var unheardEpisodesLabel: UILabel!

    // MARK: - Initializers

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!

        initialize()
    }

    func initialize() {
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
        backgroundColor = ColorPalette.TableView.Cell.Background
        accessoryType = .DisclosureIndicator
    }

    override func awakeFromNib() {
        super.awakeFromNib()

//        logoImageView.contentMode = .ScaleAspectFill
        titleLabel.textColor = ColorPalette.TableView.Cell.Title
        authorLabel.textColor = ColorPalette.TableView.Cell.Title
        unheardEpisodesLabel.textColor = ColorPalette.TableView.Cell.Subtitle
    }
}
