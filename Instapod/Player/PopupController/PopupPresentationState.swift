//
//  PopupPresentationState.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

enum PopupPresentationState: UInt {
    case hidden
    case closed
    case transitioning
    case open
}
