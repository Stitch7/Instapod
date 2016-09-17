//
//  UIColor+hexString.swift
//  Instapod
//
//  Created by Christopher Reitz on 24.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIColor {
    var hexString: String {
        let components = self.cgColor.components
        let r = Float((components?[0])!)
        let g = Float((components?[1])!)
        let b = Float((components?[2])!)

        return String(NSString(format: "#%02lX%02lX%02lX",
            lroundf(r * 255.0),
            lroundf(g * 255.0),
            lroundf(b * 255.0)
        ))
    }
}
