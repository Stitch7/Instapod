//
//  PopupCloseButton.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PopupCloseButton: UIButton {

    // MARK: - Private Properties

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
        setTitleColor(UIColor.black, for: UIControlState())
        configureLayer()
        configureBackground()
        configureImage()
        configureEvents()
    }

    func configureLayer() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 3.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.masksToBounds = false
    }

    func configureBackground() {
        let blurEffect = UIBlurEffect(style: .extraLight)
        backgroundView = UIVisualEffectView(effect: blurEffect)
        backgroundView.isUserInteractionEnabled = false
        addSubview(backgroundView)

        let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect)
        let highlightEffectView = UIVisualEffectView(effect: vibrancyEffect)
        highlightEffectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        highlightEffectView.frame = backgroundView.contentView.bounds

        highlightView = UIView(frame: highlightEffectView.contentView.bounds)
        highlightView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        highlightView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        highlightView.alpha = 0.0

        highlightEffectView.contentView.addSubview(highlightView)
        backgroundView.addSubview(highlightEffectView)
    }

    func configureImage() {
        let bundle = Bundle(for: type(of: self))
        let image = UIImage(named: "DismissChevron", in: bundle, compatibleWith: nil)
        setImage(image, for: UIControlState())
    }

    func configureEvents() {
        addTarget(self, action: #selector(didTouchDown), for: .touchDown)
        addTarget(self, action: #selector(didTouchDragExit), for: .touchDragExit)
        addTarget(self, action: #selector(didTouchDragEnter), for: .touchDragEnter)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpInside)
        addTarget(self, action: #selector(didTouchUp), for: .touchUpOutside)
        addTarget(self, action: #selector(didTouchCancel), for: .touchCancel)
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

    func highlighted(_ highlighted: Bool, animated: Bool) {
        let alphaBlock: ()->() = { [weak self] in
            guard let popupCloseButton = self else { return }
            popupCloseButton.highlightView.alpha = highlighted ? 1.0 : 0.0;
            popupCloseButton.highlightView.alpha = highlighted ? 1.0 : 0.0;
        }

        if animated {
            UIView.animate(withDuration: 0.47, animations: { alphaBlock() }) 
        }
        else {
            alphaBlock()
        }
    }

    // MARK: - UIView

    override func layoutSubviews() {
        super.layoutSubviews()

        sendSubview(toBack: backgroundView)

        let minSideSize = min(self.bounds.size.width, self.bounds.size.height)

        backgroundView.frame = bounds

        let maskLayer = CAShapeLayer()
        maskLayer.rasterizationScale = 2.0 * UIScreen.main.nativeScale
        maskLayer.shouldRasterize = true
        maskLayer.path = CGPath(roundedRect: bounds, cornerWidth: minSideSize / 2, cornerHeight: minSideSize / 2, transform: nil)
        backgroundView.layer.mask = maskLayer

        var imageFrame = imageView!.frame
        imageFrame.origin.y += 0.5
        imageView!.frame = imageFrame
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.width += 14
        sizeThatFits.height += 2

        return sizeThatFits
    }
}
