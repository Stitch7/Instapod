//
//  PopupController.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PopupController: PopupItemDelegate {

    // MARK: - Properties

    let containerController: UIViewController

    var bottomBar: UIView!
    var popupBar: PopupBar!

    var currentPopupItem: PopupItem!
    var currentContentController: UIViewController!

    var dismissalOverride = false

    var popupControllerState: PopupPresentationState
    var popupControllerTargetState: PopupPresentationState

    var popupBarLongPressGestureRecognizer: UILongPressGestureRecognizer!
    var popupBarLongPressGestureRecognizerDelegate: PopupControllerLongPressGestureDelegate!
    var popupBarTapGestureRecognizer: UITapGestureRecognizer!

    var lastPopupBarLocation: CGPoint!
    var lastSeenMovement: CFTimeInterval = 0.0

    var effectiveStatusBarUpdateController: UIViewController! // ???

    var cachedDefaultFrame = CGRectZero
    var cachedOpenPopupFrame = CGRectZero

    var tresholdToPassForStatusBarUpdate: CGFloat = 0.0
    var statusBarTresholdDir: CGFloat = 0.0

    // MARK: - Initializers

    init(containerController: UIViewController) {
        self.containerController = containerController
        popupControllerState = .Hidden
        popupControllerTargetState = .Hidden
    }

    var frameForOpenPopupBar: CGRect {
        let defaultFrame = containerController.defaultFrameForBottomDockingView
        return CGRectMake(defaultFrame.origin.x, popupBar.frame.size.height * -1, containerController.view.bounds.size.width, popupBar.frame.size.height)
    }

    var frameForClosedPopupBar: CGRect {
        let defaultFrame =  containerController.defaultFrameForBottomDockingView
        return CGRectMake(defaultFrame.origin.x, defaultFrame.origin.y - popupBar.frame.size.height, containerController.view.bounds.size.width, popupBar.frame.size.height)
    }

    func repositionPopupContent() {
        let relativeFrameForContentView = bottomBar.frame

        let percent = percentFromPopupBarForBottomBarDisplacement
        var bottomBarFrame = cachedDefaultFrame
        bottomBarFrame.origin.y += (percent * bottomBarFrame.size.height)
        bottomBar.frame = bottomBarFrame

        let alpha = 1.0 - percent
        popupBar.toolbar.alpha = alpha
        popupBar.progressView.alpha = alpha

        var contentFrame = containerController.view.bounds
        contentFrame.origin.x = popupBar.frame.origin.x
        contentFrame.origin.y = popupBar.frame.origin.y + popupBar.frame.size.height
        contentFrame.size.height = relativeFrameForContentView.origin.y - (popupBar.frame.origin.y + popupBar.frame.size.height)

        popupContentView.frame = contentFrame

        if let popupContentViewController = containerController.popupContentViewController {
            popupContentViewController.view.frame = containerController.view.bounds
        }

        popupContentView.popupCloseButton.sizeToFit()
        var popupCloseButtonFrame = popupContentView.popupCloseButton.frame
        popupCloseButtonFrame.origin.x = 12

        let app = UIApplication.sharedApplication()
        let yOffset = app.statusBarHidden ? 0 : app.statusBarFrame.size.height
        popupCloseButtonFrame.origin.y = 12 + yOffset

        if let currentContentController = currentContentController as? UINavigationController {
            if currentContentController.navigationBarHidden == false {
                popupCloseButtonFrame.origin.y += CGRectGetHeight(currentContentController.navigationBar.bounds)
            }
        }

        if CGRectEqualToRect(popupContentView.popupCloseButton.frame, popupCloseButtonFrame) == false {
            UIView.animateWithDuration(0.2) {
                self.popupContentView.popupCloseButton.frame = popupCloseButtonFrame
            }
        }
    }

    func saturate(x: CGFloat) -> CGFloat {
        return max(0, min(1, x))
    }

    func smoothstep(a a: CGFloat, b: CGFloat, x: CGFloat) -> CGFloat {
        let t = saturate((x - a) / (b - a))
        return t * t * (3.0 - (2.0 * t))
    }

    var percentFromPopupBar: CGFloat {
        return 1 - (popupBar.center.y / cachedDefaultFrame.origin.y)
    }

    var percentFromPopupBarForBottomBarDisplacement: CGFloat {
        return smoothstep(a: 0.05, b: 1.0, x: percentFromPopupBar)
    }

    func setContentToState(state: PopupPresentationState) {
        var targetFrame = popupBar.frame

        if state == .Open {
            targetFrame = frameForOpenPopupBar
        }
        else if state == .Closed {
            targetFrame = frameForClosedPopupBar
        }

        cachedDefaultFrame = containerController.defaultFrameForBottomDockingView

        popupBar.frame = targetFrame

        if state != .Transitioning {
            containerController.setNeedsStatusBarAppearanceUpdate()
        }

        repositionPopupContent()

    }

    func transitionToState(state: PopupPresentationState, animated: Bool, completion completionBlock: (() -> Void)?, userOriginatedTransition: Bool) {
        if state == popupControllerState { return }
        if userOriginatedTransition && popupControllerState == .Transitioning {
            print("The popup controller is already in transition. Transition request will be ignored!")
            return
        }
        guard let contentController = containerController.popupContentViewController else {
            print("contentController not present")
            return
        }

        if popupControllerState == .Closed {
            contentController.beginAppearanceTransition(true, animated: false)
            UIView.performWithoutAnimation {
                contentController.view.frame = self.containerController.view.bounds
                contentController.view.clipsToBounds = false
                contentController.view.autoresizingMask = .None

                if CGColorGetAlpha(contentController.view.backgroundColor!.CGColor) < 1.0 { // iOS8 Support
                    let style = self.popupBar.barStyle == .Default
                        ? UIBlurEffectStyle.ExtraLight
                        : UIBlurEffectStyle.Dark
                    let effect = UIBlurEffect(style: style)
                    self.popupContentView.setValue(effect, forKey: "effect")
                }
                else {
                    self.popupContentView.setValue(nil, forKey: "effect")
                }

                self.popupContentView.contentView.addSubview(contentController.view)
                self.popupContentView.contentView.sendSubviewToBack(contentController.view)
                self.popupContentView.contentView.setNeedsLayout()
                self.popupContentView.contentView.layoutIfNeeded()
            }
            contentController.endAppearanceTransition()

            popupBar.removeGestureRecognizer(popupContentView.popupInteractionGestureRecognizer)
            contentController.viewForPopupInteractionGestureRecognizer.addGestureRecognizer(popupContentView.popupInteractionGestureRecognizer)
        }

        popupControllerState = .Transitioning
        popupControllerTargetState = state

        var popupContentViewController: PopupContentViewController = containerController.popupContentViewController
        if let navigationController = self.containerController as? UINavigationController {
            popupContentViewController = navigationController.popupContentViewController
//            if let navigationController2 = navigationController.visibleViewController as? UINavigationController {
//                popupContentViewController = navigationController2.popupContentViewController
//            }
        }

        if state == .Closed {
            popupContentViewController.popupControllerWillHide()
        }
        else {
            popupContentViewController.popupControllerWillAppear()
        }

        let duration = animated ? 0.5 : 0.0
        UIView.animateWithDuration(duration,
            delay: 0.0,
            usingSpringWithDamping: 500,
            initialSpringVelocity: 0,
            options: [],
            animations: { () -> Void in
                if state == .Closed {
                    contentController.beginAppearanceTransition(true, animated: false)
                }
                
                self.setContentToState(state)
            },
            completion: { (finished) -> Void in
                if state == .Closed {
                    contentController.view.removeFromSuperview()
                    contentController.endAppearanceTransition()

                    contentController.viewForPopupInteractionGestureRecognizer.removeGestureRecognizer(self.popupContentView.popupInteractionGestureRecognizer)
                    self.popupBar.addGestureRecognizer(self.popupContentView.popupInteractionGestureRecognizer)
                    popupContentViewController.popupControllerDidHide()
                }
                else if state == .Open {
                    popupContentViewController.popupControllerDidAppear()
                }
                
                self.popupControllerState = state

                if let completion = completionBlock {
                    completion()
                }
            }
        )
    }

    @objc func popupBarLongPressGestureRecognized(gestureRecognizer: UILongPressGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            popupBar.highlighted = true
        case .Cancelled:
            fallthrough
        case .Ended:
            popupBar.highlighted = false
        default: break
        }
    }

    @objc func popupBarTapGestureRecognized(gestureRecognizer: UITapGestureRecognizer) {
        if gestureRecognizer.state == .Ended {
            transitionToState(.Open, animated: true, completion: nil, userOriginatedTransition: false)
        }
    }

    @objc func popupBarPresentationByUserPanGestureHandler(gestureRecognizer: UIPanGestureRecognizer) {
        if dismissalOverride { return }

        switch gestureRecognizer.state {
        case .Began:
            lastSeenMovement = CACurrentMediaTime()
            popupBarLongPressGestureRecognizer.enabled = false
            popupBarLongPressGestureRecognizer.enabled = true
            lastPopupBarLocation = popupBar.center

            statusBarTresholdDir = popupControllerState == .Open ? 1 : -1
            tresholdToPassForStatusBarUpdate = -10

            transitionToState(.Transitioning, animated: true, completion: nil, userOriginatedTransition: false)

            cachedDefaultFrame = containerController.defaultFrameForBottomDockingView
            cachedOpenPopupFrame = frameForOpenPopupBar

        case .Changed:
            var targetCenterY = min(lastPopupBarLocation.y + gestureRecognizer.translationInView(popupBar.superview).y, cachedDefaultFrame.origin.y - popupBar.frame.size.height / 2)
            targetCenterY = max(targetCenterY, cachedOpenPopupFrame.origin.y + popupBar.frame.size.height / 2)

            let currentCenterY = popupBar.center.y
            popupBar.center = CGPointMake(popupBar.center.x, targetCenterY)
            repositionPopupContent()
            lastSeenMovement = CACurrentMediaTime()

            if (statusBarTresholdDir == 1 && currentCenterY < targetCenterY && targetCenterY >= tresholdToPassForStatusBarUpdate) ||
               (statusBarTresholdDir == -1 && currentCenterY > targetCenterY && targetCenterY < tresholdToPassForStatusBarUpdate)
            {
                statusBarTresholdDir = -statusBarTresholdDir
                containerController.setNeedsStatusBarAppearanceUpdate()
            }
        case .Cancelled:
            fallthrough
        case .Ended:
            let panThreshold = (CACurrentMediaTime() - lastSeenMovement) <= PopupBarGesturePanThreshold
            let heightTreshold = percentFromPopupBar > PopupBarGestureHeightPercentThreshold
            let isPanUp = gestureRecognizer.velocityInView(containerController.view).y < 0
            let hasPassedOffset = gestureRecognizer.translationInView(popupBar.superview).y <= PopupBarGestureSnapOffset
            let state: PopupPresentationState =
                (panThreshold || heightTreshold) && (isPanUp || hasPassedOffset)
                    ? .Open
                    : .Closed

            transitionToState(state, animated: true, completion: nil, userOriginatedTransition: false)
        default: break
        }
    }

    func positionForBar(bar: UIBarPositioning) -> UIBarPosition {
        return .Any
    }

    @objc func closePopupContent() {
        closePopupAnimated(true, completion: nil)
    }

    func _reconfigure_title() {
        popupBar.title = currentPopupItem.title
    }

    func _reconfigure_subtitle()  {
        popupBar.subtitle = currentPopupItem.subtitle
    }

    func _reconfigure_progress() {
        UIView.performWithoutAnimation() {
            self.popupBar.progressView.setProgress(self.currentPopupItem.progress, animated: false)
        }
    }

    func _reconfigureBarItems() {
        popupBar.delayBarButtonLayout()
        popupBar.leftBarButtonItems = currentPopupItem.leftBarButtonItems
        popupBar.rightBarButtonItems = currentPopupItem.rightBarButtonItems
        popupBar.layoutBarButtonItems()
    }

    func _reconfigure_leftBarButtonItems() {
        _reconfigureBarItems()
    }
    
    func _reconfigure_rightBarButtonItems() {
        _reconfigureBarItems()
    }

    func _reconfigureContent() {
        if currentPopupItem != nil {
            currentPopupItem.itemDelegate = nil
        }

        currentPopupItem = containerController.popupContentViewController!.popupItem
        currentPopupItem.itemDelegate = self
        popupBar.popupItem = currentPopupItem

        if let currentContentController = self.currentContentController {
            let newContentController = containerController.popupContentViewController!
            let oldContentViewFrame = currentContentController.view.frame

            newContentController.beginAppearanceTransition(true, animated: false)
            let coordinator = PopupTransitionCoordinator()
            newContentController.willTransitionToTraitCollection(containerController.traitCollection, withTransitionCoordinator: coordinator)
            newContentController.viewWillTransitionToSize(containerController.view.bounds.size, withTransitionCoordinator: coordinator)
            newContentController.view.frame = oldContentViewFrame
            newContentController.view.clipsToBounds = false
            self.popupContentView.contentView.insertSubview(newContentController.view, belowSubview: currentContentController.view)
            newContentController.endAppearanceTransition()

            currentContentController.beginAppearanceTransition(false, animated: false)
            currentContentController.view.removeFromSuperview()
            currentContentController.endAppearanceTransition()
            
            self.currentContentController = newContentController
        }

//        for key in ["title", "subtitle", "progress", "leftBarButtonItems"] {
            popupItem(currentPopupItem, didChangeValueForKey: "") // TODO
//        }

    }

    func configurePopupBarFromBottomBar() {
        if let bottomBar = bottomBar as? PopupBar {
            popupBar.systemBarStyle = bottomBar.barStyle
            popupBar.systemBarTintColor = bottomBar.barTintColor
        }

        popupBar.systemTintColor = bottomBar.tintColor
        popupBar.systemBackgroundColor = bottomBar.backgroundColor
    }

    func movePopupBarAndContentToBottomBarSuperview() {
        assert(bottomBar.superview != nil, "Bottom docking view must have a superview before presenting popup.")
        popupBar.removeFromSuperview()
        bottomBar.superview!.insertSubview(popupBar, belowSubview: bottomBar)
        popupBar.superview!.bringSubviewToFront(popupBar)
        popupBar.superview!.bringSubviewToFront(bottomBar)
        popupBar.superview!.insertSubview(popupContentView, belowSubview: popupBar)
    }

    var _popupContentView: PopupContentView!
    var popupContentView: PopupContentView {
        if _popupContentView != nil {
            return _popupContentView!
        }

        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(popupBarPresentationByUserPanGestureHandler(_:)))

        let closeButton = PopupCloseButton(frame: CGRectZero)
        closeButton.clipsToBounds = true
        closeButton.addTarget(self, action: #selector(closePopupContent), forControlEvents: .TouchUpInside)

        _popupContentView = PopupContentView(
            frame: containerController.view.bounds,
            popupBarStyle: popupBar.barStyle,
            popupInteractionGestureRecognizer: gestureRecognizer,
            popupCloseButton: closeButton
        )

        _popupContentView.contentView.addSubview(closeButton)

        _popupContentView.layer.masksToBounds = true
        _popupContentView.preservesSuperviewLayoutMargins = true
        _popupContentView.contentView.preservesSuperviewLayoutMargins = true

        return _popupContentView
    }

    func presentPopupBarAnimated(animated: Bool, openPopup open: Bool, completion completionBlock: (() -> Void)?) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)), name: UIApplicationWillEnterForegroundNotification, object: nil)

        if let popupContentViewController = containerController.popupContentViewController {
            let coordinator = PopupTransitionCoordinator()
            popupContentViewController.willTransitionToTraitCollection(containerController.traitCollection, withTransitionCoordinator: coordinator)
            popupContentViewController.viewWillTransitionToSize(containerController.view.bounds.size, withTransitionCoordinator: coordinator)
        }

        if popupControllerTargetState == .Hidden {
            dismissalOverride = false

            self.popupControllerState = .Closed
            self.popupControllerTargetState = .Closed

            bottomBar = containerController.bottomDockingViewForPopup

            popupBar = PopupBar(frame: CGRectZero)
            popupBar.hidden = false

            movePopupBarAndContentToBottomBarSuperview()
            configurePopupBarFromBottomBar()

            popupBarLongPressGestureRecognizerDelegate = PopupControllerLongPressGestureDelegate()
            popupBarLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(popupBarLongPressGestureRecognized(_:)))
            popupBarLongPressGestureRecognizer.minimumPressDuration = 0
            popupBarLongPressGestureRecognizer.cancelsTouchesInView = false
            popupBarLongPressGestureRecognizer.delaysTouchesBegan = false
            popupBarLongPressGestureRecognizer.delaysTouchesEnded = false
            popupBarLongPressGestureRecognizer.delegate = popupBarLongPressGestureRecognizerDelegate
            popupBar.addGestureRecognizer(popupBarLongPressGestureRecognizer)

            popupBarTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(popupBarTapGestureRecognized(_:)))
            popupBar.addGestureRecognizer(popupBarTapGestureRecognizer)
            popupBar.addGestureRecognizer(popupContentView.popupInteractionGestureRecognizer)

            setContentToState(.Closed)
            containerController.view.layoutIfNeeded()
            
            _reconfigureContent()

            let duration = animated ? 0.5 : 0.0
            UIView.animateWithDuration(duration,
                delay: 0.0,
                usingSpringWithDamping: 500,
                initialSpringVelocity: 0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: { () -> Void in
                    var barFrame = self.popupBar.frame
                    barFrame.size.height = self.popupBar.popupBarHeight

                    self.popupBar.frame = barFrame;
                    self.popupBar.frame = self.frameForClosedPopupBar

                    PopupSupportFixInsetsForViewController(self.containerController, layout: true)
                    
                    if open {
                        self.openPopupAnimated(animated, completion: completionBlock)
                    }
                },
                completion: { (finished) -> Void in
                    if let completion = completionBlock {
                        completion()
                    }
                }
            )
        }
        else {
            _reconfigureContent()

            if open {
                openPopupAnimated(animated, completion: completionBlock)
            }

            if let completion = completionBlock {
                completion()
            }
        }

        currentContentController = containerController.popupContentViewController
    }

    func openPopupAnimated(animated: Bool, completion: (() -> Void)?) {
        transitionToState(.Open, animated: animated, completion: completion, userOriginatedTransition: true)
    }

    func closePopupAnimated(animated: Bool, completion: (() -> Void)?) {
        transitionToState(.Closed, animated: animated, completion: completion, userOriginatedTransition: true)
    }

    func dismissPopupBarAnimated(animated: Bool, completion completionBlock: (() -> Void)?) {
        if popupControllerState == .Hidden { return }

        let dismissalAnimationCompletionBlock: () -> Void = {
            let duration = animated ? 0.5 : 0.0
            UIView.animateWithDuration(duration,
                delay: 0.0,
                usingSpringWithDamping: 500,
                initialSpringVelocity: 0,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: { () -> Void in
                    var barFrame = self.popupBar.frame
                    barFrame.size.height = 0
                    self.popupBar.frame = barFrame

                    PopupSupportFixInsetsForViewController(self.containerController, layout: true)
                },
                completion: { (finished) -> Void in
                    self.popupControllerTargetState = .Hidden
                    self.popupControllerState = .Hidden

                    self.bottomBar.frame = self.containerController.defaultFrameForBottomDockingView
                    self.bottomBar = nil

                    self.popupBar.removeFromSuperview()
                    self.popupBar = nil

                    self.popupContentView.removeFromSuperview()
//                    self.popupContentView = nil

                    self.popupBarLongPressGestureRecognizerDelegate = nil
                    self.popupBarLongPressGestureRecognizer = nil
                    self.popupBarTapGestureRecognizer = nil
//                    self.popupContentView.popupInteractionGestureRecognizer = nil

                    PopupSupportFixInsetsForViewController(self.containerController, layout: true)

                    let notificationCenter = NSNotificationCenter.defaultCenter()
                    notificationCenter.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
                    notificationCenter.removeObserver(self, name: UIApplicationWillEnterForegroundNotification, object: nil)
                    
                    self.currentContentController = nil
                    self.effectiveStatusBarUpdateController = nil // ???
                    
                    if let completion = completionBlock {
                        completion()
                    }
                }
            )
        }

        if popupControllerTargetState != .Closed {
            popupBar.hidden = true
            dismissalOverride = true
            popupContentView.popupInteractionGestureRecognizer.enabled = false
            popupContentView.popupInteractionGestureRecognizer.enabled = true
            transitionToState(.Closed, animated: animated, completion: dismissalAnimationCompletionBlock, userOriginatedTransition: false)
        }
        else {
            dismissalAnimationCompletionBlock()
        }
    }

    // MARK: - PopupItemDelegate

    func popupItem(popupItem: PopupItem, didChangeValueForKey key: String) {

        _reconfigure_title()
        _reconfigure_subtitle()
        _reconfigure_progress()
        _reconfigure_leftBarButtonItems()

// DISPATCH IT
//        let reconfigureSelector = "_reconfigure_\(key)"
//        print(reconfigureSelector)
//        void (*configureDispatcher)(id, SEL) = (void(*)(id, SEL))objc_msgSend;
//        configureDispatcher(self, NSSelectorFromString(reconfigureSelector));
    }


    // MARK: - Application Events

    @IBAction func applicationDidEnterBackground(application: UIApplication) {
//        print("KTHXBYE!")
//        popupBar.setTitleViewMarqueesPaused(true)
    }

    @IBAction func applicationWillEnterForeground(application: UIApplication) {
//        print("Huhu")        
//        popupBar.setTitleViewMarqueesPaused(false)
    }

}
