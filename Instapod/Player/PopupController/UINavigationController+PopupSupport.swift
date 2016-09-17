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
        if let isHidden = objc_getAssociatedObject(self, &ToolbarHiddenBeforeTransition) as? Bool {
            return isHidden
        }
        else {
            return self.isToolbarHidden
        }
    }

    func setToolbarHiddenDuringTransition(_ toolbarHidden: Bool) {
        objc_setAssociatedObject(self, &ToolbarHiddenBeforeTransition, self.isToolbarHidden, .OBJC_ASSOCIATION_RETAIN);
    }

    override var bottomDockingViewForPopup_nocreate: UIView {
        return self.toolbar
    }

    override var bottomDockingViewForPopup: UIView {
        return self.toolbar
    }

    override open class func initialize() {
        super.initialize()

        _popup_nav_load()
    }

    class func _popup_nav_load() {
//        var onceToken: Int = 0
//        dispatch_once(&onceToken) {
            let edInsBase64 = "X2VkZ2VJbnNldHNGb3JDaGlsZFZpZXdDb250cm9sbGVyOmluc2V0c0FyZUFic29sdXRlOg==" // _edgeInsetsForChildViewController:insetsAreAbsolute:
            var data = Data(base64Encoded: edInsBase64, options: [])!
            var selName = String(data: data, encoding: String.Encoding.utf8)!

            var m1 = class_getInstanceMethod(UIViewController.self, NSSelectorFromString(selName))
            var m2 = class_getInstanceMethod(UIViewController.self, #selector(UINavigationController.eIFCVC(_:iAA:)))
            method_exchangeImplementations(m1, m2)

            let sTHedBase64 = "X3NldFRvb2xiYXJIaWRkZW46ZWRnZTpkdXJhdGlvbjo=" // _setToolbarHidden:edge:duration:
            data = Data(base64Encoded: sTHedBase64, options: [])!
            selName = String(data: data, encoding: String.Encoding.utf8)!
            m1 = class_getInstanceMethod(UIViewController.self, NSSelectorFromString(selName))
            m2 = class_getInstanceMethod(UIViewController.self, #selector(UINavigationController._sTH(_:e:d:)))
            method_exchangeImplementations(m1, m2)
//        }
    }

    func _sTH(_ arg1: Bool, e arg2: Int, d arg3: Double) {
        setToolbarHiddenDuringTransition(isToolbarHidden == arg1 && arg1 == true)
        _popupController_nocreate!.setContentToState(self._popupController_nocreate!.popupControllerState)
        _popupController_nocreate!.popupBar.isHidden = isToolbarHiddenDuringTransition
        _popupController_nocreate!.popupContentView.isHidden = isToolbarHiddenDuringTransition
        _popupController_nocreate!.movePopupBarAndContentToBottomBarSuperview()

        let coordinator = self.transitionCoordinator!
        coordinator.animateAlongsideTransition(in: self._popupController_nocreate!.popupBar.superview,
            animation: { (context) -> Void in
                self._popupController_nocreate!.setContentToState(self._popupController_nocreate!.popupControllerState)
            },
            completion: { (context) -> Void in
                self.setToolbarHiddenDuringTransition(arg1)
                self._popupController_nocreate!.movePopupBarAndContentToBottomBarSuperview()

                self._popupController_nocreate!.popupBar.isHidden = self.isToolbarHiddenDuringTransition
                self._popupController_nocreate!.popupContentView.isHidden = self.isToolbarHiddenDuringTransition
            }
        )
    }

    override func eIFCVC(_ controller: UIViewController, iAA absolute: Bool) -> UIEdgeInsets {
        var rv = self._popup_common_eIFCVC(controller, iAA:absolute)

        if self._popupController_nocreate!.popupControllerState != .hidden && self.isToolbarHidden {
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
