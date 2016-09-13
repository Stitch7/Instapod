//
//  MulticastDelegate.swift
//  Instapod
//
//  Created by Christopher Reitz on 12.09.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//

import Foundation

class MulticastDelegate<T> {

    private var weakDelegates = [WeakWrapper]()

    func addDelegate(delegate: T) {
        guard delegate is AnyObject else {
            fatalError("MulticastDelegate does not support value types")
        }

        weakDelegates.append(WeakWrapper(value: delegate as! AnyObject))
    }

    func removeDelegate(delegate: T) {
        guard delegate is AnyObject else { return }

        for (index, delegateInArray) in weakDelegates.enumerate().reverse() {
            if delegateInArray.value === (delegate as! AnyObject) {
                weakDelegates.removeAtIndex(index)
            }
        }
    }

    func invoke(invocation: (T) -> ()) {
        // Reverse order prevents race condition when removing elements
        for (index, delegate) in weakDelegates.enumerate().reverse() {
            // Since these are weak references, "value" may be nil
            // at some point when ARC is 0 for the object.
            // Else, ARC killed it, get rid of the element from our array
            guard let delegate = delegate.value else {
                weakDelegates.removeAtIndex(index)
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
