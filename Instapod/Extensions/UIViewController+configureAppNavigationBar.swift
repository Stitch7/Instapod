//
//  UIViewController+configureAppNavigationBar.swift
//  Instapod
//
//  Created by Christopher Reitz on 21.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIViewController {
    func configureAppNavigationBar() {
        guard let navigationBar = navigationController?.navigationBar else { return }

        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let navigationBarColor = ColorPalette.Background.colorWithAlphaComponent(0.9)

        navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        navigationBar.shadowImage = UIImage()
        navigationBar.backgroundColor = navigationBarColor

        let statusBarView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: 20.0))
        statusBarView.backgroundColor = navigationBarColor
        navigationController?.view.addSubview(statusBarView)
    }
}
