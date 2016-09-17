//
//  UIImage+createThumbnail.swift
//  Instapod
//
//  Created by Christopher Reitz on 03.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

extension UIImage {
    func createThumbnail(size baseSize: CGFloat) -> Data? {
        let length = UIScreen.main.scale * baseSize
        let size = CGSize(width: length, height: length)

        UIGraphicsBeginImageContext(size)
        self.draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let thumbnailImage = UIGraphicsGetImageFromCurrentImageContext()

        var thumbnailData: Data?
        if let png = UIImagePNGRepresentation(thumbnailImage!) {
            thumbnailData = NSData(data: png) as Data
        }
        else if let jpeg = UIImageJPEGRepresentation(thumbnailImage!, 1.0) {
            thumbnailData = NSData(data: jpeg) as Data
        }
        UIGraphicsEndImageContext()

        return thumbnailData
    }
}
