//
//  PodcastCollectionViewCell.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PodcastCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    var imageData: NSData? {
        didSet {
            guard let data = imageData else { return }
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                let thumbnailImage = UIImage(data: data)
                dispatch_async(dispatch_get_main_queue()) {
                    self.imageView.image = thumbnailImage
                }
            }
        }
    }

    // MARK: - IB Outlets

    @IBOutlet weak var imageView: UIImageView!
}
