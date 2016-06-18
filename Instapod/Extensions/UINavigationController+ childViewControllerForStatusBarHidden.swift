//
//  UINavigationController+ childViewControllerForStatusBarHidden.swift
//  Instapod
//
//  Created by Christopher Reitz on 24.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UINavigationController {
    public override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return self.topViewController
    }

    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return self.topViewController
    }
}

extension UISplitViewController {
    public override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return self.viewControllers.first
    }

    public override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return self.viewControllers.first
    }
}
