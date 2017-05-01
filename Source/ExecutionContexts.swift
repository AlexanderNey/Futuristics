//
//  ExecutionContexts.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation

@discardableResult
public func onMainQueue<T, U>(_ closure: (T) throws -> U) -> ((T) -> Future<U>) {
    let mainQueue = DispatchQueue.main
    return onQueue(mainQueue)(closure)
}


@discardableResult
public func onBackgroundQueue<T, U>(_ closure: (T) throws -> U) -> ((T) -> Future<U>) {
    let aBackgroundQueue = DispatchQueue.global(qos: .default)
    return onQueue(aBackgroundQueue)(closure)
}

@discardableResult
public func onQueue<T, U>(_ queue: DispatchQueue) -> (_ closure: (T) throws -> U) -> ((T) -> Future<U>) {
    return { [queue] (closure: @escaping (T) throws -> U) in
        return onQueue(queue, closure: closure)
    } as! ((T) throws -> U) -> ((T) -> Future<U>)
}

@discardableResult
private func onQueue<T, U>(_ queue: DispatchQueue, closure: @escaping (T) throws -> U) -> ((T) -> Future<U>) {
    return { (parameter: T) in
        let promise = Promise<U>()
        if queue === DispatchQueue.main && Thread.isMainThread {
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
    assert(!Thread.isMainThread, "await will block main thread")
    if #available(iOS 10.0, *), #available(watchOSApplicationExtension 3.0, *) {
        dispatchPrecondition(condition: .notOnQueue(DispatchQueue.main))
    }

    let semaphore = DispatchSemaphore(value: 0)
    
    futures.forEach { future in
        future.finally {
            semaphore.signal()
        }
    }
    
    futures.forEach { _ in
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
}

public func awaitResult<T>(_ future: Future<T>) throws -> T {
    await(future)
    return try future.result()
}

