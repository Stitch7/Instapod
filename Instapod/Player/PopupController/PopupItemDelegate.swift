//
//  PopupItemDelegate.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

protocol PopupItemDelegate {
    func popupItem(_ popupItem: PopupItem, didChangeValueForKey key: String)
}
