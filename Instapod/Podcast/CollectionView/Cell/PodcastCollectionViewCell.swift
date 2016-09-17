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

    var imageData: Data? {
        didSet {
            guard let data = imageData else { return }
            DispatchQueue.global(qos: .userInitiated).async {
                let thumbnailImage = UIImage(data: data)
                DispatchQueue.main.async {
                    self.imageView.image = thumbnailImage
                }
            }
        }
    }

    // MARK: - IB Outlets

    @IBOutlet weak var imageView: UIImageView!
}
