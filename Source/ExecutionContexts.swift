//
//  ExecutionContexts.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation

public enum AsynchError : Error {
    case awaitTimedOut
}


@discardableResult public func onMainQueue<T, U>(_ closure: @escaping (T) throws -> U) -> ((T) -> Future<U>) {
    let mainQueue = DispatchQueue.main
    return onQueue(mainQueue)(closure)
}


@discardableResult public func onBackgroundQueue<T, U>(_ closure: @escaping (T) throws -> U) -> ((T) -> Future<U>) {
    let aBackgroundQueue = DispatchQueue.global(qos: .userInitiated)
    return onQueue(aBackgroundQueue)(closure)
}

@discardableResult public func onQueue<T, U>(_ queue: DispatchQueue) -> (_ closure: @escaping (T) throws -> U) -> ((T) -> Future<U>) {
    return { [queue] (closure: @escaping (T) throws -> U) in
        return onQueue(queue, closure: closure)
    }
}

@discardableResult private func onQueue<T, U>(_ queue: DispatchQueue, closure: @escaping (T) throws -> U) -> ((T) -> Future<U>) {
    return { (parameter: T) in
        let promise = Promise<U>()
        if queue === DispatchQueue.main && Thread.isMainThread {
            defer { promise.ensureResolution() }
            promise.resolveWith { try closure(parameter) }
        } else {
            queue.async {
                defer { promise.ensureResolution() }
                promise.resolveWith { try closure(parameter) }
            }
        }
        return promise.future
    }
}

public func await<T>(_ futures: Future<T> ...) {
    await(futures)
}

public func await<T>(_ futures: [Future<T>]) {
    guard !Thread.isMainThread else {
        fatalError("await will block main thread")
    }
    let semaphore = DispatchSemaphore(value: 0)
    
    futures.forEach { future in
        future.finally {
            semaphore.signal()
        }
    }
    
    futures.forEach { future in
        let result = semaphore.wait(timeout: DispatchTime.distantFuture)
        /* Handling the timeout case makes really only sense if the await 
        function can be parameterized with a specific timeout */
        if case DispatchTimeoutResult.timedOut = result {
            future.reject(AsynchError.awaitTimedOut)
        }
    }
}

public func awaitResult<T>(_ future: Future<T>) throws -> T {
    await(future)
    return try future.getResult()
}
