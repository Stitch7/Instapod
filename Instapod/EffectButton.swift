//
//  EffectButton.swift
//  Instapod
//
//  Created by Christopher Reitz on 17.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class EffectButton: UIButton {

    // MARK: - Properties

    var backgroundView: UIVisualEffectView!
    var highlightView: UIView!

    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        initialize()
    }

    func initialize() {
        titleLabel?.font = UIFont.boldSystemFontOfSize(11)
        setTitleColor(UIColor.blackColor(), forState: .Normal)
        configureLayer()
        configureBackground()
        configureEvents()
    }

    func configureLayer() {
        layer.shadowColor = UIColor.blackColor().CGColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 3.0
        layer.shadowOffset = CGSizeMake(0, 0)
        layer.masksToBounds = false
    }

    func configureBackground() {
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        backgroundView = UIVisualEffectView(effect: blurEffect)
        backgroundView.userInteractionEnabled = false
        addSubview(backgroundView)

        let vibrancyEffect = UIVibrancyEffect(forBlurEffect: blurEffect)
        let highlightEffectView = UIVisualEffectView(effect: vibrancyEffect)
        highlightEffectView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        highlightEffectView.frame = backgroundView.contentView.bounds

        highlightView = UIView(frame: highlightEffectView.contentView.bounds)
        highlightView.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.2)
        highlightView.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        highlightView.alpha = 0.0

        highlightEffectView.contentView.addSubview(highlightView)
        backgroundView.addSubview(highlightEffectView)
    }

    func configureEvents() {
        addTarget(self, action: #selector(didTouchDown), forControlEvents: .TouchDown)
        addTarget(self, action: #selector(didTouchDragExit), forControlEvents: .TouchDragExit)
        addTarget(self, action: #selector(didTouchDragEnter), forControlEvents: .TouchDragEnter)
        addTarget(self, action: #selector(didTouchUp), forControlEvents: .TouchUpInside)
        addTarget(self, action: #selector(didTouchUp), forControlEvents: .TouchUpOutside)
        addTarget(self, action: #selector(didTouchCancel), forControlEvents: .TouchCancel)
    }

    // MARK: - Events

    func didTouchDown() {
        highlighted(true, animated: false)
    }

    func didTouchDragExit() {
        highlighted(false, animated: true)
    }

    func didTouchDragEnter() {
        highlighted(true, animated: true)
    }

    func didTouchUp() {
        highlighted(false, animated: true)
    }

    func didTouchCancel() {
        highlighted(false, animated: true)
    }

    func highlighted(highlighted: Bool, animated: Bool) {
        let alphaBlock: dispatch_block_t = { [weak self] in
            guard let popupCloseButton = self else { return }
            popupCloseButton.highlightView.alpha = highlighted ? 1.0 : 0.0
            popupCloseButton.highlightView.alpha = highlighted ? 1.0 : 0.0
        }

        if animated {
            UIView.animateWithDuration(0.47) { alphaBlock() }
        }
        else {
            alphaBlock()
        }
    }

    // MARK: - UIView

    override func layoutSubviews() {
        super.layoutSubviews()

        sendSubviewToBack(backgroundView)

        let minSideSize = min(self.bounds.size.width, self.bounds.size.height)

        backgroundView.frame = bounds

        let maskLayer = CAShapeLayer()
        maskLayer.rasterizationScale = 2.0 * UIScreen.mainScreen().nativeScale
        maskLayer.shouldRasterize = true
        maskLayer.path = CGPathCreateWithRoundedRect(bounds, minSideSize / 2, minSideSize / 2, nil)
        backgroundView.layer.mask = maskLayer

        var imageFrame = imageView!.frame
        imageFrame.origin.y += 0.5
        imageView!.frame = imageFrame
    }

    override func sizeThatFits(size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.width += 14
        sizeThatFits.height += 2
        
        return sizeThatFits
    }
}

