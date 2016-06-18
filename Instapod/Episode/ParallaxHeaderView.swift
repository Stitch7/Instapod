//
//  ParallaxHeaderView.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class ParallaxHeaderView: UIView {

    // MARK: - Properties

    var headerImage = UIImage() {
        didSet {
            imageView.image = headerImage
            refreshBlurViewForNewImage()
        }
    }

    var headerTitleLabel = UILabel()
    var imageScrollView = UIScrollView()
    var imageView = UIImageView()
    var bluredImageView = UIImageView()
    var subView: UIView?

    var kDefaultHeaderFrame = CGRect()
    let kParallaxDeltaFactor: CGFloat = 0.5
    let kMaxTitleAlphaOffset: CGFloat = 100.0
    let kLabelPaddingDist: CGFloat = 8.0

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)

        kDefaultHeaderFrame = CGRectMake(0, 0, frame.size.width, frame.size.height)
    }

    convenience init(image: UIImage, forSize headerSize: CGSize) {
        self.init(frame: CGRectMake(0, 0, headerSize.width, headerSize.height))

        headerImage = image
        initialSetupForDefaultHeader()
    }

    convenience init(subView: UIView) {
        self.init(frame: CGRectMake(0, 0, subView.frame.size.width, subView.frame.size.height))

        initialSetupForCustomSubView(subView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        if let subView = self.subView {
            initialSetupForCustomSubView(subView)
        }
        else {
            initialSetupForDefaultHeader()
        }
    }

    func layoutHeaderViewForScrollViewOffset(offset: CGPoint) {
        if offset.y > 0 {
            var frame = imageScrollView.frame
            frame.origin.y = max(offset.y * kParallaxDeltaFactor, 0)
            imageScrollView.frame = frame
            bluredImageView.alpha = 1 / kDefaultHeaderFrame.size.height * offset.y * 2
            clipsToBounds = true

            let titleAlpha = frame.origin.y * 1 / kMaxTitleAlphaOffset / 1.5
            headerTitleLabel.alpha = titleAlpha
        }
        else {
            let delta: CGFloat = fabs(min(0.0, offset.y))
            var rect = kDefaultHeaderFrame
            rect.origin.y -= delta
            rect.size.height += delta
            imageScrollView.frame = rect
            clipsToBounds = false

            let titleAlpha = delta * 1 / kMaxTitleAlphaOffset
            headerTitleLabel.alpha = titleAlpha
        }
    }

    func refreshBlurViewForNewImage() {
        let radius: CGFloat = 5
        let tintColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)

        if let bluredImage = headerImage.applyBlurWithRadius(radius,
                                                             tintColor: tintColor,
                                                             saturationDeltaFactor: 1.0,
                                                             maskImage: nil)
        {
            bluredImageView.image = bluredImage
        }
    }

    // MARK: - Private

    private func initialSetupForDefaultHeader() {
        imageScrollView = UIScrollView(frame: bounds)
        imageView = UIImageView(frame: imageScrollView.bounds)
        imageView.autoresizingMask = [
            .FlexibleLeftMargin,
            .FlexibleRightMargin,
            .FlexibleTopMargin,
            .FlexibleBottomMargin,
            .FlexibleHeight,
            .FlexibleWidth
        ]
        imageView.contentMode = .ScaleAspectFill
        imageView.image = headerImage
        imageScrollView.addSubview(imageView)

        var labelRect = imageScrollView.bounds
        labelRect.origin.x = kLabelPaddingDist
        labelRect.origin.y = kLabelPaddingDist
        labelRect.size.width = labelRect.size.width - 2 * kLabelPaddingDist
        labelRect.size.height = labelRect.size.height - 2 * kLabelPaddingDist

        bluredImageView = UIImageView(frame: imageView.frame)
        bluredImageView.autoresizingMask = imageView.autoresizingMask
        bluredImageView.alpha = 0.0
        imageScrollView.addSubview(bluredImageView)

        headerTitleLabel = UILabel(frame: labelRect)
        headerTitleLabel.textAlignment = .Center
        headerTitleLabel.numberOfLines = 0
        headerTitleLabel.lineBreakMode = .ByWordWrapping
        headerTitleLabel.autoresizingMask = imageView.autoresizingMask
        headerTitleLabel.alpha = 0.0
        headerTitleLabel.textColor = headerImage.averageColor().isBright() ? UIColor.blackColor() : UIColor.whiteColor()
        headerTitleLabel.font = UIFont.systemFontOfSize(23.0)
        imageScrollView.addSubview(headerTitleLabel)

        headerTitleLabel.hidden = true

        addSubview(imageScrollView)
        refreshBlurViewForNewImage()
    }

    private func initialSetupForCustomSubView(subView: UIView) {
        let scrollView = UIScrollView(frame: bounds)
        imageScrollView = scrollView
        self.subView = subView
        subView.autoresizingMask = [
            .FlexibleLeftMargin,
            .FlexibleRightMargin,
            .FlexibleTopMargin,
            .FlexibleBottomMargin,
            .FlexibleHeight,
            .FlexibleWidth
        ]
        imageScrollView.addSubview(subView)

        bluredImageView = UIImageView(frame: subView.frame)
        bluredImageView.autoresizingMask = subView.autoresizingMask
        bluredImageView.alpha = 0.0
        imageScrollView.addSubview(bluredImageView)

        addSubview(imageScrollView)
        refreshBlurViewForNewImage()
    }
}
