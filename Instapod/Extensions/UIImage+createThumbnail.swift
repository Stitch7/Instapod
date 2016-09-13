//
//  UIImage+createThumbnail.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIImage {
    func createThumbnail(size baseSize: CGFloat) -> NSData? {
        let length = UIScreen.mainScreen().scale * baseSize
        let size = CGSizeMake(length, length)

        UIGraphicsBeginImageContext(size)
        self.drawInRect(CGRectMake(0.0, 0.0, size.width, size.height))
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()

        var thumbnailData: NSData?
        if let png = UIImagePNGRepresentation(thumbnailImage) {
            thumbnailData = NSData(data: png)
        }
        else if let jpeg = UIImageJPEGRepresentation(thumbnailImage, 1.0) {
            thumbnailData = NSData(data: jpeg)
        }
        UIGraphicsEndImageContext()

        return thumbnailData
    }
}
