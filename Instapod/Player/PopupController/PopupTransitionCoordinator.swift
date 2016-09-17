//
//  PopupTransitionCoordinator.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PopupTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {

    var isAnimated : Bool {
        return false
    }

    var presentationStyle : UIModalPresentationStyle {
        return .none
    }

    var initiallyInteractive : Bool {
        return false
    }

    var isInterruptible: Bool {
        return false
    }

    var isInteractive : Bool {
        return false
    }

    var isCancelled : Bool {
        return false
    }

    var transitionDuration : TimeInterval {
        return 0.0
    }

    var percentComplete : CGFloat {
        return 1.0
    }

    var completionVelocity : CGFloat {
        return 1.0
    }

    var completionCurve : UIViewAnimationCurve {
        return .easeInOut
    }

    func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
//        if key == UITransitionContextFromViewControllerKey { }
//        else if key == UITransitionContextToViewControllerKey { }
        return nil
    }

    func view(forKey key: UITransitionContextViewKey) -> UIView? {
        return nil
    }

    var containerView : UIView {
        return UIView() // should nil
    }

    var targetTransform : CGAffineTransform {
        return CGAffineTransform.identity
    }

    func animate(
        alongsideTransition animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        if let animation = animation {
            animation(self)
        }
        else if let completion = completion {
            completion(self)
        }

        return true
    }

    func animateAlongsideTransition(
        in view: UIView?,
        animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        return animate(alongsideTransition: animation, completion: completion)
    }

    func notifyWhenInteractionEnds(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {
    }

    func notifyWhenInteractionChanges(_ handler: @escaping (UIViewControllerTransitionCoordinatorContext) -> Void) {
    }
}
