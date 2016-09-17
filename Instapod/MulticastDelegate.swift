//
//  MulticastDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

class MulticastDelegate<T> {

    fileprivate var weakDelegates = [WeakWrapper]()

    func addDelegate(_ delegate: T) {
        /*// TODO: cast is always true in swift3 */
//        guard delegate is AnyObject else {
//            fatalError("MulticastDelegate does not support value types")
//        }

        weakDelegates.append(WeakWrapper(value: delegate as AnyObject))
    }

    func removeDelegate(_ delegate: T) {
        /*// TODO: cast is always true in swift3 */
//        guard delegate is AnyObject else { return }

        for (index, delegateInArray) in weakDelegates.enumerated().reversed() {
            if delegateInArray.value === (delegate as AnyObject) {
                weakDelegates.remove(at: index)
            }
        }
    }

    func invoke(_ invocation: (T) -> ()) {
        // Reverse order prevents race condition when removing elements
        for (index, delegate) in weakDelegates.enumerated().reversed() {
            // Since these are weak references, "value" may be nil
            // at some point when ARC is 0 for the object.
            // Else, ARC killed it, get rid of the element from our array
            guard let delegate = delegate.value else {
                weakDelegates.remove(at: index)
                continue
            }

            invocation(delegate as! T)
        }
    }
}

func += <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.addDelegate(right)
}

func -= <T: AnyObject> (left: MulticastDelegate<T>, right: T) {
    left.removeDelegate(right)
}

private class WeakWrapper {
    weak var value: AnyObject?

    init(value: AnyObject) {
        self.value = value
    }
}
