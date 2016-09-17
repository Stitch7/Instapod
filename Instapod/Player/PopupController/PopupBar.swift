//
//  PopupBar.swift
//  PopupController
//
//  Created by Christopher Reitz on 15.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class PopupBar: UIView {

    // MARK: - Constants

    let popupBarHeight: CGFloat = 40.0
    let barStyleInherit: UIBarStyle = .default

    // MARK: - Public Properties

    var toolbar: UIToolbar!
    var progressView: UIProgressView!

    var popupItem: PopupItem?

    var leftBarButtonItems: [UIBarButtonItem]? {
        didSet {
            if delaysBarButtonItemLayout == false {
                layoutBarButtonItems()
            }
        }
    }

    var rightBarButtonItems: [UIBarButtonItem]? {
        didSet {
            if delaysBarButtonItemLayout == false {
                layoutBarButtonItems()
            }
        }
    }

    var transluent: Bool {
        get {
            return backgroundView.isTranslucent
        }
        set {
            backgroundView.isTranslucent = newValue
        }
    }

    var barStyle: UIBarStyle {
        get {
            guard let backgroundView = self.backgroundView else { return .default }
            return backgroundView.barStyle
        }
        set {
//            backgroundView.barStyle = barStyle == barStyleInherit ? systemBarStyle! : barStyle
            setTitleLableFontsAccordingToBarStyleAndTint()
        }

    }
    var barTintColor: UIColor? {
        didSet {
            backgroundView.barTintColor = barTintColor ?? systemBarTintColor
            setTitleLableFontsAccordingToBarStyleAndTint()
        }
    }

    var backgroundImage: UIImage? {
        get {
            return backgroundView.backgroundImage(forToolbarPosition: .any, barMetrics: .default)
        }
        set {
            backgroundView.setBackgroundImage(newValue, forToolbarPosition: .any, barMetrics: .default)
        }
    }

    var shadowImage: UIImage? {
        get {
            return backgroundView.shadowImage(forToolbarPosition: .any)
        }
        set {
            backgroundView.setShadowImage(shadowImage, forToolbarPosition: .any)
        }
    }

    var title: String? {
        didSet {
            needsLabelsLayout = true
        }
    }
    var subtitle: String? {
        didSet {
            needsLabelsLayout = true
        }
    }

    var highlighted: Bool? {
        didSet {
            guard let highlighted = self.highlighted else { return }
            highlightView?.isHidden = !highlighted
        }
    }

    var titleTextAttributes: [String: AnyObject]?
    var subtitleTextAttributes: [String: AnyObject]?

    // MARK: - Private Properties

    var highlightView: UIView!

    var systemBarStyle: UIBarStyle?
    var systemTintColor: UIColor?
    var systemBarTintColor: UIColor?
    var systemBackgroundColor: UIColor?


    var backgroundView: UIToolbar!
    var delaysBarButtonItemLayout = false
    var titlesView: UIView!
    var titleLabel: UILabel!
    var subtitleLabel: UILabel!
    var needsLabelsLayout = false

    var userTintColor: UIColor?
    var userBackgroundColor: UIColor?


    // MARK: - Initializers

    override init(frame: CGRect) {
        super.init(frame: frame)

        initialize(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

    }

    func initialize(frame: CGRect) {
        barStyle = barStyleInherit

        backgroundView = UIToolbar(frame: frame)
        backgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(backgroundView)

        let fullFrame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.size.width, height: popupBarHeight)

        toolbar = UIToolbar(frame: fullFrame)
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbar.autoresizingMask = .flexibleWidth
        toolbar.layer.masksToBounds = true
        addSubview(toolbar)

        progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackImage = UIImage()
        progressView.progress = 0.5
        toolbar.addSubview(progressView)

        // TODO
//        let views = Dictionary(dictionaryLiteral: ("progressView", progressView))
//        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[progressView(1)]|", options: [], metrics: nil, views: views))
//        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[progressView]|", options: [], metrics: nil, views: views))

        highlightView = UIView(frame: bounds)
        highlightView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        highlightView.isUserInteractionEnabled = true
        highlightView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)

        titlesView = UIView(frame: fullFrame)
        titlesView.isUserInteractionEnabled = false
        titlesView.autoresizingMask = UIViewAutoresizing()
        layoutTitles()
        toolbar.addSubview(titlesView)

        needsLabelsLayout = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = bounds
        toolbar.bringSubview(toFront: titlesView)
        layoutTitles()
    }

    func layoutTitles() {
        DispatchQueue.main.async {
            var leftMargin: CGFloat = 0
            var rightMargin = self.bounds.size.width

            if let leftBarButtonItems = self.leftBarButtonItems {
                for (_, barButtonItem) in leftBarButtonItems.reversed().enumerated() {
                    guard let itemView = barButtonItem.value(forKey: "view") else { continue }
                    leftMargin = (itemView as AnyObject).frame.origin.x + (itemView as AnyObject).frame.size.width + 10
                }
            }

            if let rightBarButtonItems = self.rightBarButtonItems {
                for (_, barButtonItem) in rightBarButtonItems.reversed().enumerated() {
                    guard let itemView = barButtonItem.value(forKey: "view") else { continue }
                    rightMargin = (itemView as AnyObject).frame.origin.x - 10
                }
            }

            var frame = self.titlesView.frame
            frame.origin.x = leftMargin
            frame.size.width = rightMargin - leftMargin
            self.titlesView.frame = frame

            if self.needsLabelsLayout {
                if self.titleLabel == nil {
                    self.titleLabel = self.newMarqueeLabel()
                    self.titleLabel.font = UIFont.systemFont(ofSize: 12)
                    self.titlesView.addSubview(self.titleLabel)
                }

                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center

                var reset = false

                let font = UIFont.systemFont(ofSize: 12.0)

                var defaultTitleAttributes = [String: AnyObject]()
                defaultTitleAttributes["NSParagraphStyleAttributeName"] = paragraph
                defaultTitleAttributes["NSFontAttributeName"] = font
                defaultTitleAttributes["NSForegroundColorAttributeName"] = self.barStyle == .default ? UIColor.black : UIColor.white
                defaultTitleAttributes.merge(self.titleTextAttributes ?? [String: AnyObject]())

                var defaultSubtitleAttributes = [String: AnyObject]()
                defaultSubtitleAttributes["NSParagraphStyleAttributeName"] = paragraph
                defaultSubtitleAttributes["NSFontAttributeName"] = font
                defaultSubtitleAttributes["NSForegroundColorAttributeName"] = self.barStyle == .default ? UIColor.gray : UIColor.white
                defaultSubtitleAttributes.merge(self.subtitleTextAttributes ?? [String: AnyObject]())

                if self.titleLabel.text != self.title && self.title != nil {
                    self.titleLabel.attributedText = NSAttributedString(string: self.title!, attributes: defaultTitleAttributes)
                    reset = true
                }

                if self.subtitleLabel == nil {
                    self.subtitleLabel = self.newMarqueeLabel()
                    self.subtitleLabel.font = UIFont.systemFont(ofSize: 10)
                    self.titlesView.addSubview(self.subtitleLabel)
                }

                if self.subtitleLabel.text != self.subtitle && self.subtitle != nil {
                    self.subtitleLabel.attributedText = NSAttributedString(string: self.subtitle!, attributes: defaultSubtitleAttributes)
                    reset = true
                }

                if reset {
//                    self.titleLabel.resetLabel()
//                    self.subtitleLabel.resetLabel()
//                    self.titleLabel.text = ""
//                    self.subtitleLabel.text = ""
                }
            }

            self.setTitleLableFontsAccordingToBarStyleAndTint()

            var titleLabelFrame = self.titlesView.bounds
            titleLabelFrame.size.height = 40

            titleLabelFrame.origin.x = 10.0

            if self.subtitle?.characters.count > 0 {

                var subtitleLabelFrame = self.titlesView.bounds
                subtitleLabelFrame.size.height = 40

                subtitleLabelFrame.origin.x = 10.0

                titleLabelFrame.origin.y -= self.titleLabel.font.lineHeight / 2
                subtitleLabelFrame.origin.y += self.subtitleLabel.font.lineHeight / 2

                self.subtitleLabel.frame = subtitleLabelFrame
                self.subtitleLabel.isHidden = false
                
//                if self.needsLabelsLayout {
//                    if self.subtitleLabel.isPaused() && self.titleLabel.isPaused() == false {
//                        self.subtitleLabe.unpauseLabel()
//                    }
//                }
            }
            else {
                if self.needsLabelsLayout {
//                    self.subtitleLabel.resetLabel()
//                    self.subtitleLabel.pauseLabel()
                    self.subtitleLabel.isHidden = true
                }
            }
            
            self.titleLabel.frame = titleLabelFrame
            
            self.needsLabelsLayout = false
        }
    }

    func newMarqueeLabel() -> UILabel {
//        __MarqueeLabel* rv = [[__MarqueeLabel alloc] initWithFrame:_titlesView.bounds rate:20 andFadeLength:10];
//        rv.leadingBuffer = 5.0;
//        rv.trailingBuffer = 15.0;
//        rv.animationDelay = 2.0;
//        rv.marqueeType = MLContinuous;
//        return rv;

        let label = UILabel(frame: titlesView.bounds)
        return label
    }

    func setTitleLableFontsAccordingToBarStyleAndTint() {
//        if barStyle == .Default {
//            titleLabel.textColor = titleTextAttributes["NSForegroundColorAttributeName"] as? UIColor ?? UIColor.blackColor()
//            subtitleLabel.textColor = subtitleTextAttributes["NSForegroundColorAttributeName"] as? UIColor ?? UIColor.blackColor()
//        }
//        else {
//            titleLabel.textColor = _titleTextAttributes[NSForegroundColorAttributeName] ? [UIColor whiteColor];
//            subtitleLabel.textColor = _subtitleTextAttributes[NSForegroundColorAttributeName] ?: [UIColor whiteColor];
//        }
        if let titleLabel = self.titleLabel {
            titleLabel.textColor = UIColor.black
        }
        if let subtitleLabel = self.subtitleLabel {
            subtitleLabel.textColor = UIColor.black
        }
    }

    func removeAnimationFromBarItems() {
        guard let barButtonItems = toolbar.items else { return }

        for (_, barButtonItem) in barButtonItems.enumerated() {
            guard let itemView = barButtonItem.value(forKey: "view") else { continue }
            (itemView as AnyObject).layer.removeAllAnimations()
        }
    }

    // MARK: - Public

    func delayBarButtonLayout() {
        delaysBarButtonItemLayout = true
    }

    func layoutBarButtonItems() {

        var items = [UIBarButtonItem]()
        let fixed = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        items.append(fixed)

        var spacerWidth: CGFloat = 10
        if traitCollection.horizontalSizeClass == .regular {
            spacerWidth = 20
        }

        if let leftBarButtonItems = self.leftBarButtonItems {
            for (index, barButtonItem) in leftBarButtonItems.enumerated() {
                items.append(barButtonItem)

                if index != leftBarButtonItems.count - 1 {
                    let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                    spacer.width = spacerWidth
                    items.append(spacer)
                }
            }
        }

        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        if let rightBarButtonItems = self.rightBarButtonItems {
            for (index, barButtonItem) in rightBarButtonItems.enumerated() {
                items.append(barButtonItem)

                if index != rightBarButtonItems.count - 1 {
                    let spacer = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
                    spacer.width = spacerWidth
                    items.append(spacer)
                }
            }
        }

        let fixed2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixed.width = -2
        items.append(fixed2)

        toolbar.setItems(items, animated: true)
        
        layoutTitles()
        
        delaysBarButtonItemLayout = false
    }

}
