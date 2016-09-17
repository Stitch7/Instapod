//
//  UIImage+averageColor.swift
//  Instapod
//
//  Created by Christopher Reitz on 06.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIImage {
    func averageColor() -> UIColor {
        let rgba = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(data: rgba, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: info)
        var r: CGFloat
        var g: CGFloat
        var b: CGFloat
        var alpha: CGFloat

        context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        if rgba[3] > 0 {
            alpha = CGFloat(rgba[3]) / 255.0
            let multiplier = alpha / 255.0
            r = CGFloat(rgba[0]) * multiplier
            g = CGFloat(rgba[1]) * multiplier
            b = CGFloat(rgba[2]) * multiplier

            return UIColor(red: r, green: g, blue: b, alpha: alpha)
        }
        else {
            r = CGFloat(rgba[0]) / 255.0
            g = CGFloat(rgba[1]) / 255.0
            b = CGFloat(rgba[2]) / 255.0
            alpha = CGFloat(rgba[3]) / 255.0
        }

        return UIColor(red: r, green: g, blue: b, alpha: alpha)
    }
}
