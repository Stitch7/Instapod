//
//  PopupTransitionCoordinator.swift
//  PopupController
//
//  Created by Christopher Reitz on 19.03.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import UIKit

class PopupTransitionCoordinator: NSObject, UIViewControllerTransitionCoordinator {

    func isAnimated() -> Bool {
        return false
    }

    func presentationStyle() -> UIModalPresentationStyle {
        return .None
    }

    func initiallyInteractive() -> Bool {
        return false
    }

    func isInteractive() -> Bool {
        return false
    }

    func isCancelled() -> Bool {
        return false
    }

    func transitionDuration() -> NSTimeInterval {
        return 0.0
    }

    func percentComplete() -> CGFloat {
        return 1.0
    }

    func completionVelocity() -> CGFloat {
        return 1.0
    }

    func completionCurve() -> UIViewAnimationCurve {
        return .EaseInOut
    }

    func viewControllerForKey(key: String) -> UIViewController? {
//        if key == UITransitionContextFromViewControllerKey { }
//        else if key == UITransitionContextToViewControllerKey { }
        return nil
    }

    func viewForKey(key: String) -> UIView? {
        return nil
    }

    func containerView() -> UIView {
        return UIView() // should nil
    }

    func targetTransform() -> CGAffineTransform {
        return CGAffineTransformIdentity
    }

    func animateAlongsideTransition(
        animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
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

    func animateAlongsideTransitionInView(
        view: UIView?,
        animation: ((UIViewControllerTransitionCoordinatorContext) -> Void)?,
        completion: ((UIViewControllerTransitionCoordinatorContext) -> Void)?
    ) -> Bool {
        return animateAlongsideTransition(animation, completion: completion)
    }

    func notifyWhenInteractionEndsUsingBlock(handler: (UIViewControllerTransitionCoordinatorContext) -> Void) {
    }
}
