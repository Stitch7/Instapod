//
//  AsynchronousOperation.swift
//  Instapod
//
//  Created by Christopher Reitz on 09.04.16.
//  Copyright © 2016 Christopher Reitz. All rights reserved.
//
//
//  Performs all of the necessary KVN of `isFinished` and `isExecuting` for a
//  concurrent `NSOperation` subclass. Subclasses should:
//
//  - override `main()` with the tasks that initiate the asynchronous task;
//
//  - call `completeOperation()` function when the asynchronous task is done;
//
//  - optionally, periodically check `self.cancelled` status, performing any clean-up
//    necessary and then ensuring that `completeOperation()` is called; or
//    override `cancel` method, calling `super.cancel()` and then cleaning-up
//    and ensuring `completeOperation()` is called.
//

import Foundation

class AsynchronousOperation: Operation {

    override var isAsynchronous: Bool { return true }

    fileprivate var _executing: Bool = false
    override var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            if _executing == newValue { return }

            willChangeValue(forKey: "isExecuting")
            _executing = newValue
            didChangeValue(forKey: "isExecuting")
        }
    }

    fileprivate var _finished: Bool = false
    override var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if _finished == newValue { return }

            willChangeValue(forKey: "isFinished")
            _finished = newValue
            didChangeValue(forKey: "isFinished")
        }
    }

    func completeOperation() {
        if isExecuting {
            isExecuting = false
            isFinished = true
        }
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true
        main()
    }
}
