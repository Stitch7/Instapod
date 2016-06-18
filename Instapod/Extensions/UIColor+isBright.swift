//
//  UIColor+isBright.swift
//  Instapod
//
//  Created by Christopher Reitz on 23.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIColor {
    func isBright() -> Bool {
        let count = CGColorGetNumberOfComponents(CGColor)
        let componentColors = CGColorGetComponents(CGColor)
        let r = componentColors[0] * 255.0
        let g = componentColors[1] * 255.0
        let b = componentColors[2] * 255.0

        var brightnessScore: CGFloat = 0.0
        if count == 2 {
            brightnessScore = ((r * 299.0) + (r * 587.0) + (r * 114.0)) / 1000.0
        }
        else if count == 4 {
            brightnessScore = ((r * 299.0) + (g * 587.0) + (b * 114.0)) / 1000.0
        }

        return brightnessScore >= 125.0
    }
}
