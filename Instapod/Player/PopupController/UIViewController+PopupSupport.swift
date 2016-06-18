//
//  UIViewController+PopupSupport.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import ObjectiveC

let PopupBarGesturePanThreshold: CFTimeInterval = 0.1
let PopupBarGestureHeightPercentThreshold: CGFloat = 0.2
let PopupBarGestureSnapOffset: CGFloat = 40

var ContentViewControllerObjectHandle: UInt8 = 0
var ContainerViewControllerObjectHandle: UInt8 = 0
var PopupControllerObjectHandle: UInt8 = 0
var PopupItemObjectHandle: UInt8 = 0
var BottomBarSupportObjectHandle: UInt8 = 0

func PopupSupportFixInsetsForViewController(controller: UIViewController, layout: Bool) {
    for childViewController in controller.childViewControllers {
        PopupSupportFixInsetsForViewController(childViewController, layout: false)
    }

    if layout {
        controller.view.setNeedsUpdateConstraints()
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }
}

class PopupBottomBarSupport: UIView {
}

protocol PopupContentDelegate {
    func popupControllerWillHide()
    func popupControllerDidHide()
    func popupControllerWillAppear()
    func popupControllerDidAppear()
}

class PopupContentViewController: UIViewController, PopupContentDelegate {
    func popupControllerWillHide() { }
    func popupControllerDidHide() { }
    func popupControllerWillAppear() { }
    func popupControllerDidAppear() { }
}

extension UIViewController {

    override public class func initialize() {
        super.initialize()

        _popup_load()
    }

    class func _popup_load() {
        var onceToken: dispatch_once_t = 0
        dispatch_once(&onceToken) {
            var m1 = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidLayoutSubviews))
            var m2 = class_getInstanceMethod(UIViewController.self, #selector(UIViewController._popup_viewDidLayoutSubviews))
            method_exchangeImplementations(m1, m2)

            m1 = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.setNeedsStatusBarAppearanceUpdate))
            m2 = class_getInstanceMethod(UIViewController.self, #selector(UIViewController._popup_setNeedsStatusBarAppearanceUpdate))
            method_exchangeImplementations(m1, m2)

            m1 = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.childViewControllerForStatusBarStyle))
            m2 = class_getInstanceMethod(UIViewController.self, Selector("_popup_childViewControllerForStatusBarStyle"))
            method_exchangeImplementations(m1, m2)

            m1 = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.childViewControllerForStatusBarHidden))
            m2 = class_getInstanceMethod(UIViewController.self, Selector("_popup_childViewControllerForStatusBarHidden"))
            method_exchangeImplementations(m1, m2)

            let vCUSBBase64 = "X3ZpZXdDb250cm9sbGVyVW5kZXJsYXBzU3RhdHVzQmFy" // _viewControllerUnderlapsStatusBar
            let data = NSData(base64EncodedString: vCUSBBase64, options: [])!
            let selName = String(data: data, encoding: NSUTF8StringEncoding)!
            m1 = class_getInstanceMethod(UIViewController.self, NSSelectorFromString(selName))
            m2 = class_getInstanceMethod(UIViewController.self, Selector("_vCUSB"))
            method_exchangeImplementations(m1, m2)
        }
    }

    func _popup_setNeedsStatusBarAppearanceUpdate() {
        if let popupPresentationContainerViewController = self.popupPresentationContainerViewController {
            popupPresentationContainerViewController.setNeedsStatusBarAppearanceUpdate()
        }
        else {
            _popup_setNeedsStatusBarAppearanceUpdate()
        }
    }

    func _popup_viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if _popupController_nocreate != nil {
            popupContentViewController.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        }

        _popup_viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    func _popup_willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        if _popupController_nocreate != nil {
            popupContentViewController.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        }

        _popup_willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
    }

    var _popup_common_childViewControllerForStatusBarHidden: UIViewController? {
        guard let popupController = _popupController_nocreate else { return _popup_childViewControllerForStatusBarHidden }

        if popupController.popupControllerTargetState.rawValue > PopupPresentationState.Closed.rawValue &&
           popupController.popupBar.center.y < -10
        {
            return self.popupContentViewController
        }

        return _popup_childViewControllerForStatusBarHidden
    }

    var _popup_common_childViewControllerForStatusBarStyle: UIViewController? {
        guard let popupController = _popupController_nocreate else { return _popup_childViewControllerForStatusBarStyle }

        if popupController.popupControllerTargetState.rawValue > PopupPresentationState.Closed.rawValue &&
           popupController.popupBar.center.y < -10
        {
            return popupContentViewController
        }

        return _popup_childViewControllerForStatusBarStyle
    }


    var _popup_childViewControllerForStatusBarHidden: UIViewController? {
        return _popup_common_childViewControllerForStatusBarHidden
    }

    var _popup_childViewControllerForStatusBarStyle: UIViewController? {
        return _popup_common_childViewControllerForStatusBarStyle
    }

    func eIFCVC(controller: UIViewController, iAA absolute: Bool) -> UIEdgeInsets {
        return UIEdgeInsetsZero
    }

    func _popup_common_eIFCVC(controller: UIViewController, iAA absolute: Bool) -> UIEdgeInsets {
        var insets = eIFCVC(controller, iAA: absolute)

        if controller == popupContentViewController {
            insets.top = controller.prefersStatusBarHidden() == false ? UIApplication.sharedApplication().statusBarFrame.size.height : 0
            insets.bottom = 0.0

            return insets
        }

        if _popupController.popupControllerState != .Hidden {
            insets.bottom += _popupController_nocreate!.popupBar.frame.size.height
        }

        return insets
    }

    var _vCUSB: Bool {
        if popupPresentationContainerViewController != nil {
            let statusBarVC = childViewControllerForStatusBarHidden() ?? self
            return statusBarVC.prefersStatusBarHidden() == false
        }

        return self._vCUSB
    }

    func _popup_viewDidLayoutSubviews()  {
        _popup_viewDidLayoutSubviews()

        if bottomDockingViewForPopup_nocreate != nil {
            if bottomDockingViewForPopup == _bottomBarSupport  {
                _bottomBarSupport.frame = defaultFrameForBottomDockingView
                view.bringSubviewToFront(self._bottomBarSupport)
            }
            else {
                _bottomBarSupport.hidden = true
            }
    
            if _popupController_nocreate != nil && _popupController_nocreate!.popupControllerState != .Hidden {
                _popupController_nocreate!.setContentToState(_popupController_nocreate!.popupControllerState)
            }
        }
    } 

    func presentPopupBarWithContentViewController(controller: PopupContentViewController, openPopup: Bool, animated: Bool, completion completionBlock: (() -> Void)?) {
        popupContentViewController = controller
        popupContentViewController.popupPresentationContainerViewController = self

        _popupController.presentPopupBarAnimated(animated, openPopup: openPopup, completion: completionBlock)
    }

    var popupContentViewController: PopupContentViewController! {
        get {
            return objc_getAssociatedObject(self, &ContentViewControllerObjectHandle) as? PopupContentViewController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &ContentViewControllerObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    var popupPresentationContainerViewController: UIViewController? {
        get {
            return objc_getAssociatedObject(self, &ContainerViewControllerObjectHandle) as? UIViewController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &ContainerViewControllerObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func openPopupAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        _popupController.openPopupAnimated(animated, completion: completion)
    }

    func closePopupAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        _popupController.closePopupAnimated(animated, completion: completion)
    }

    func dismissPopupBarAnimated(animated: Bool, completion: (() -> Void)? = nil) {
        _popupController.dismissPopupBarAnimated(animated) {
            if let completion = completion {
                completion()
            }
        }
    }

    func updatePopupBarAppearance() {
        _popupController.configurePopupBarFromBottomBar()
    }

    var popupPresentationState: PopupPresentationState {
        return _popupController.popupControllerState
    }

    var _popupController_nocreate: PopupController? {
        return objc_getAssociatedObject(self, &PopupControllerObjectHandle) as? PopupController
    }

    var _popupController: PopupController {
        var rv = _popupController_nocreate
        if rv == nil {
            rv = PopupController(containerController: self)
            objc_setAssociatedObject(self, &PopupControllerObjectHandle, rv, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        return rv!
    }

    var popupItem: PopupItem {
        var rv = objc_getAssociatedObject(self, &PopupItemObjectHandle) as? PopupItem
        if rv == nil {
            rv = PopupItem()
            objc_setAssociatedObject(self, &PopupItemObjectHandle, rv, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            rv!.containerController = self
        }

        return rv!
    }

    var popupBar: PopupBar {
        return _popupController.popupBar
    }

    var popupContentView: PopupContentView {
        return _popupController.popupContentView
    }

    var viewForPopupInteractionGestureRecognizer: UIView {
        return view
    }

    var _bottomBarSupport_nocreate: PopupBottomBarSupport? {
        return objc_getAssociatedObject(self, &BottomBarSupportObjectHandle) as? PopupBottomBarSupport
    }

    var _bottomBarSupport: PopupBottomBarSupport {
        var rv = _bottomBarSupport_nocreate
        if rv == nil {
            let frame = CGRectMake(0, view.bounds.size.height, view.bounds.size.width, 0)
            rv = PopupBottomBarSupport(frame: frame)
            objc_setAssociatedObject(self, &BottomBarSupportObjectHandle, rv, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            view.addSubview(rv!)
        }
        
        return rv!
    }

    var bottomDockingViewForPopup_nocreate: UIView? {
        return _bottomBarSupport_nocreate
    }

    var bottomDockingViewForPopup: UIView? {
        return _bottomBarSupport
    }

    var defaultFrameForBottomDockingView: CGRect {
        return CGRectMake(0, view.bounds.size.height, view.bounds.size.width, 0);
    }
}
