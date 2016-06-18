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

class AsynchronousOperation: NSOperation {

    override var asynchronous: Bool { return true }

    private var _executing: Bool = false
    override var executing: Bool {
        get {
            return _executing
        }
        set {
            if _executing == newValue { return }

            willChangeValueForKey("isExecuting")
            _executing = newValue
            didChangeValueForKey("isExecuting")
        }
    }

    private var _finished: Bool = false
    override var finished: Bool {
        get {
            return _finished
        }
        set {
            if _finished == newValue { return }

            willChangeValueForKey("isFinished")
            _finished = newValue
            didChangeValueForKey("isFinished")
        }
    }

    func completeOperation() {
        if executing {
            executing = false
            finished = true
        }
    }

    override func start() {
        if cancelled {
            finished = true
            return
        }

        executing = true
        main()
    }
}
