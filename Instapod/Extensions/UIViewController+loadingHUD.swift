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
    func loadingHUD(show show: Bool, dimsBackground: Bool = false) {
        if show {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            PKHUD.sharedHUD.dimsBackground = dimsBackground
            PKHUD.sharedHUD.userInteractionOnUnderlyingViewsEnabled = !dimsBackground
            HUD.show(.Progress)
        }
        else {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            HUD.hide(animated: true)
        }
    }

    func errorHUD() {
        HUD.show(.Error)
    }
}
