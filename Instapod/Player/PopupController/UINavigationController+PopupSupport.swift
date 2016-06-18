//
//  UINavigationController+PopupSupport.swift
//  Instapod
//
//  Created by Christopher Reitz on 28.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

var ToolbarHiddenBeforeTransition: UInt8 = 0

extension UINavigationController {
    var isToolbarHiddenDuringTransition: Bool {
        let isHidden = objc_getAssociatedObject(self, &ToolbarHiddenBeforeTransition)

        if isHidden == nil {
            return self.toolbarHidden
        }

        return isHidden.boolValue
    }

    func setToolbarHiddenDuringTransition(toolbarHidden: Bool) {
        objc_setAssociatedObject(self, &ToolbarHiddenBeforeTransition, self.toolbarHidden, .OBJC_ASSOCIATION_RETAIN);
    }

    override var bottomDockingViewForPopup_nocreate: UIView {
        return self.toolbar
    }

    override var bottomDockingViewForPopup: UIView {
        return self.toolbar
    }

    override public class func initialize() {
        super.initialize()

        _popup_nav_load()
    }

    class func _popup_nav_load() {
        var onceToken: dispatch_once_t = 0
        dispatch_once(&onceToken) {
            let edInsBase64 = "X2VkZ2VJbnNldHNGb3JDaGlsZFZpZXdDb250cm9sbGVyOmluc2V0c0FyZUFic29sdXRlOg==" // _edgeInsetsForChildViewController:insetsAreAbsolute:
            var data = NSData(base64EncodedString: edInsBase64, options: [])!
            var selName = String(data: data, encoding: NSUTF8StringEncoding)!

            var m1 = class_getInstanceMethod(UIViewController.self, NSSelectorFromString(selName))
            var m2 = class_getInstanceMethod(UIViewController.self, #selector(UINavigationController.eIFCVC(_:iAA:)))
            method_exchangeImplementations(m1, m2)

            let sTHedBase64 = "X3NldFRvb2xiYXJIaWRkZW46ZWRnZTpkdXJhdGlvbjo=" // _setToolbarHidden:edge:duration:
            data = NSData(base64EncodedString: sTHedBase64, options: [])!
            selName = String(data: data, encoding: NSUTF8StringEncoding)!
            m1 = class_getInstanceMethod(UIViewController.self, NSSelectorFromString(selName))
            m2 = class_getInstanceMethod(UIViewController.self, #selector(UINavigationController._sTH(_:e:d:)))
            method_exchangeImplementations(m1, m2)
        }
    }

    func _sTH(arg1: Bool, e arg2: Int, d arg3: Double) {
        setToolbarHiddenDuringTransition(toolbarHidden == arg1 && arg1 == true)
        _popupController_nocreate!.setContentToState(self._popupController_nocreate!.popupControllerState)
        _popupController_nocreate!.popupBar.hidden = isToolbarHiddenDuringTransition
        _popupController_nocreate!.popupContentView.hidden = isToolbarHiddenDuringTransition
        _popupController_nocreate!.movePopupBarAndContentToBottomBarSuperview()

        let coordinator = self.transitionCoordinator()!
        coordinator.animateAlongsideTransitionInView(self._popupController_nocreate!.popupBar.superview,
            animation: { (context) -> Void in
                self._popupController_nocreate!.setContentToState(self._popupController_nocreate!.popupControllerState)
            },
            completion: { (context) -> Void in
                self.setToolbarHiddenDuringTransition(arg1)
                self._popupController_nocreate!.movePopupBarAndContentToBottomBarSuperview()

                self._popupController_nocreate!.popupBar.hidden = self.isToolbarHiddenDuringTransition
                self._popupController_nocreate!.popupContentView.hidden = self.isToolbarHiddenDuringTransition
            }
        )
    }

    override func eIFCVC(controller: UIViewController, iAA absolute: Bool) -> UIEdgeInsets {
        var rv = self._popup_common_eIFCVC(controller, iAA:absolute)

        if self._popupController_nocreate!.popupControllerState != .Hidden && self.toolbarHidden {
            rv.bottom -= self._popupController_nocreate!.popupBar.frame.size.height
        }
        
        return rv
    }

    var _childViewControllerForStatusBarHidden: UIViewController? {
        return self._popup_common_childViewControllerForStatusBarHidden
    }

    var _childViewControllerForStatusBarStyle: UIViewController? {
        return self._popup_common_childViewControllerForStatusBarStyle
    }
}
