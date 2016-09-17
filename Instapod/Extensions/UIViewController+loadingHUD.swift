//
//  UIViewController+loadingHUD.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit
import PKHUD

extension UIViewController {
    func loadingHUD(show: Bool, dimsBackground: Bool = false) {
        if show {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            PKHUD.sharedHUD.dimsBackground = dimsBackground
            PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = !dimsBackground
            HUD.show(.progress)
        }
        else {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            HUD.hide(animated: true)
        }
    }

    func errorHUD() {
        HUD.show(.error)
    }
}
