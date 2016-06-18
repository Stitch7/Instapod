//
//  PopupContentView.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PopupContentView: UIVisualEffectView {

    let popupInteractionGestureRecognizer: UIPanGestureRecognizer
    let popupCloseButton: PopupCloseButton

    convenience init(
        frame: CGRect,
        popupInteractionGestureRecognizer: UIPanGestureRecognizer,
        popupCloseButton: PopupCloseButton
    ) {
        self.init(
            frame: frame,
            popupBarStyle: .Default,
            popupInteractionGestureRecognizer: popupInteractionGestureRecognizer,
            popupCloseButton: popupCloseButton
        )
    }

    init(
        frame: CGRect,
        popupBarStyle: UIBarStyle,
        popupInteractionGestureRecognizer: UIPanGestureRecognizer,
        popupCloseButton: PopupCloseButton

    ) {
        self.popupInteractionGestureRecognizer = popupInteractionGestureRecognizer
        self.popupCloseButton = popupCloseButton

        super.init(effect: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("PopupContentView: init(coder:) has not been implemented")
    }
}
