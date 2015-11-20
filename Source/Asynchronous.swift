//
//  Executor.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public func onMainQueue<T, U>(closure: T throws -> U) -> (T -> Future<U>) {
    return onMainQueue(after: nil)(closure)
}

public func onMainQueue<T, U>(after delay: Double? = nil)(_ closure: T throws -> U) -> (T -> Future<U>) {
    return onQueue(dispatch_get_main_queue(), after: delay)(closure)
}

public func onBackgroundQueue<T, U>(closure: T throws -> U) -> (T -> Future<U>) {
    return onBackgroundQueue(after: nil)(closure)
}

public func onBackgroundQueue<T, U>(after delay: Double? = nil)(_ closure: T throws -> U) -> (T -> Future<U>) {
    return onQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), after: delay)(closure)
}

public func onQueue<T, U>(queue: dispatch_queue_t, closure: T throws -> U) -> (T -> Future<U>) {
    return onQueue(queue, after: nil)(closure)
}

public func onQueue<T, U>(queue: dispatch_queue_t, after delay: Double? = nil)(_ closure: T throws -> U) -> (T -> Future<U>) {
    return { (parameter: T) in
        let promise = Promise<U>()
        if let delay = delay {
            let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
            dispatch_after(dispatchTime, queue) {
                defer { promise.ensureResolution() }
                promise.resolve { try closure(parameter) }
            }
        } else {
            if queue === dispatch_get_main_queue() && NSThread.isMainThread() {
                defer { promise.ensureResolution() }
                promise.resolve { try closure(parameter) }
            } else {
                dispatch_async(queue) {
                    defer { promise.ensureResolution() }
                    promise.resolve { try closure(parameter) }
                }
            }
        }
        return promise.future
    }
}

public func await<T>(futures: Future<T> ...) {
    await(futures)
}

public func await<T>(futures: [Future<T>]) {
    guard !NSThread.isMainThread() else {
        fatalError("await will block main thread")
    }
    let semaphore = dispatch_semaphore_create(0)
    
    futures.forEach { future in
        future.finally {
            dispatch_semaphore_signal(semaphore)
        }
    }
    
    futures.forEach { _ in
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
}