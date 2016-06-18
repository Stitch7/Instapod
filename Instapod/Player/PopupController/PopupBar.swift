//
//  PopupBar.swift
//  PopupController
//
//  Created by Christopher Reitz on 15.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PopupBar: UIView {

    // MARK: - Constants

    let popupBarHeight: CGFloat = 40.0
    let barStyleInherit: UIBarStyle = .Default

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
            return backgroundView.translucent
        }
        set {
            backgroundView.translucent = newValue
        }
    }

    var barStyle: UIBarStyle {
        get {
            guard let backgroundView = self.backgroundView else { return .Default }
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
            return backgroundView.backgroundImageForToolbarPosition(.Any, barMetrics: .Default)
        }
        set {
            backgroundView.setBackgroundImage(newValue, forToolbarPosition: .Any, barMetrics: .Default)
        }
    }

    var shadowImage: UIImage? {
        get {
            return backgroundView.shadowImageForToolbarPosition(.Any)
        }
        set {
            backgroundView.setShadowImage(shadowImage, forToolbarPosition: .Any)
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
            highlightView?.hidden = !highlighted
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

    func initialize(frame frame: CGRect) {
        barStyle = barStyleInherit

        backgroundView = UIToolbar(frame: frame)
        backgroundView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        addSubview(backgroundView)

        let fullFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, popupBarHeight)

        toolbar = UIToolbar(frame: fullFrame)
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .Any, barMetrics: .Default)
        toolbar.autoresizingMask = .FlexibleWidth
        toolbar.layer.masksToBounds = true
        addSubview(toolbar)

        progressView = UIProgressView(progressViewStyle: .Default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.trackImage = UIImage()
        progressView.progress = 0.5
        toolbar.addSubview(progressView)

        let views = Dictionary(dictionaryLiteral: ("progressView", progressView))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[progressView(1)]|", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[progressView]|", options: [], metrics: nil, views: views))

        highlightView = UIView(frame: bounds)
        highlightView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        highlightView.userInteractionEnabled = true
        highlightView.backgroundColor = UIColor.lightGrayColor().colorWithAlphaComponent(0.2)

        titlesView = UIView(frame: fullFrame)
        titlesView.userInteractionEnabled = false
        titlesView.autoresizingMask = .None
        layoutTitles()
        toolbar.addSubview(titlesView)

        needsLabelsLayout = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        backgroundView.frame = bounds
        toolbar.bringSubviewToFront(titlesView)
        layoutTitles()
    }

    func layoutTitles() {
        dispatch_async(dispatch_get_main_queue()) {
            var leftMargin: CGFloat = 0
            var rightMargin = self.bounds.size.width

            if let leftBarButtonItems = self.leftBarButtonItems {
                for (_, barButtonItem) in leftBarButtonItems.reverse().enumerate() {
                    guard let itemView = barButtonItem.valueForKey("view") else { continue }
                    leftMargin = itemView.frame.origin.x + itemView.frame.size.width + 10
                }
            }

            if let rightBarButtonItems = self.rightBarButtonItems {
                for (_, barButtonItem) in rightBarButtonItems.reverse().enumerate() {
                    guard let itemView = barButtonItem.valueForKey("view") else { continue }
                    rightMargin = itemView.frame.origin.x - 10
                }
            }

            var frame = self.titlesView.frame
            frame.origin.x = leftMargin
            frame.size.width = rightMargin - leftMargin
            self.titlesView.frame = frame

            if self.needsLabelsLayout {
                if self.titleLabel == nil {
                    self.titleLabel = self.newMarqueeLabel()
                    self.titleLabel.font = UIFont.systemFontOfSize(12)
                    self.titlesView.addSubview(self.titleLabel)
                }

                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .Center

                var reset = false

                let font = UIFont.systemFontOfSize(12.0)

                var defaultTitleAttributes = [String: AnyObject]()
                defaultTitleAttributes["NSParagraphStyleAttributeName"] = paragraph
                defaultTitleAttributes["NSFontAttributeName"] = font
                defaultTitleAttributes["NSForegroundColorAttributeName"] = self.barStyle == .Default ? UIColor.blackColor() : UIColor.whiteColor()
                defaultTitleAttributes.merge(self.titleTextAttributes ?? [String: AnyObject]())

                var defaultSubtitleAttributes = [String: AnyObject]()
                defaultSubtitleAttributes["NSParagraphStyleAttributeName"] = paragraph
                defaultSubtitleAttributes["NSFontAttributeName"] = font
                defaultSubtitleAttributes["NSForegroundColorAttributeName"] = self.barStyle == .Default ? UIColor.grayColor() : UIColor.whiteColor()
                defaultSubtitleAttributes.merge(self.subtitleTextAttributes ?? [String: AnyObject]())

                if self.titleLabel.text != self.title && self.title != nil {
                    self.titleLabel.attributedText = NSAttributedString(string: self.title!, attributes: defaultTitleAttributes)
                    reset = true
                }

                if self.subtitleLabel == nil {
                    self.subtitleLabel = self.newMarqueeLabel()
                    self.subtitleLabel.font = UIFont.systemFontOfSize(10)
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
                self.subtitleLabel.hidden = false
                
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
                    self.subtitleLabel.hidden = true
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
            titleLabel.textColor = UIColor.blackColor()
        }
        if let subtitleLabel = self.subtitleLabel {
            subtitleLabel.textColor = UIColor.blackColor()
        }
    }

    func removeAnimationFromBarItems() {
        guard let barButtonItems = toolbar.items else { return }

        for (_, barButtonItem) in barButtonItems.enumerate() {
            guard let itemView = barButtonItem.valueForKey("view") else { continue }
            itemView.layer.removeAllAnimations()
        }
    }

    // MARK: - Public

    func delayBarButtonLayout() {
        delaysBarButtonItemLayout = true
    }

    func layoutBarButtonItems() {

        var items = [UIBarButtonItem]()
        let fixed = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        items.append(fixed)

        var spacerWidth: CGFloat = 10
        if traitCollection.horizontalSizeClass == .Regular {
            spacerWidth = 20
        }

        if let leftBarButtonItems = self.leftBarButtonItems {
            for (index, barButtonItem) in leftBarButtonItems.enumerate() {
                items.append(barButtonItem)

                if index != leftBarButtonItems.count - 1 {
                    let spacer = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
                    spacer.width = spacerWidth
                    items.append(spacer)
                }
            }
        }

        items.append(UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil))

        if let rightBarButtonItems = self.rightBarButtonItems {
            for (index, barButtonItem) in rightBarButtonItems.enumerate() {
                items.append(barButtonItem)

                if index != rightBarButtonItems.count - 1 {
                    let spacer = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
                    spacer.width = spacerWidth
                    items.append(spacer)
                }
            }
        }

        let fixed2 = UIBarButtonItem(barButtonSystemItem: .FixedSpace, target: nil, action: nil)
        fixed.width = -2
        items.append(fixed2)

        toolbar.setItems(items, animated: true)
        
        layoutTitles()
        
        delaysBarButtonItemLayout = false
    }

}
