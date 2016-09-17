//
//  UINavigationController+ childViewControllerForStatusBarHidden.swift
//  Instapod
//
//  Created by Christopher Reitz on 24.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UINavigationController {
    open override var childViewControllerForStatusBarHidden : UIViewController? {
        return self.topViewController
    }

    open override var childViewControllerForStatusBarStyle : UIViewController? {
        return self.topViewController
    }
}

extension UISplitViewController {
    open override var childViewControllerForStatusBarHidden : UIViewController? {
        return self.viewControllers.first
    }

    open override var childViewControllerForStatusBarStyle : UIViewController? {
        return self.viewControllers.first
    }
}
