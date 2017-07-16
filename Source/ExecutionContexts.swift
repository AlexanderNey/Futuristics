//
//  ExecutionContexts.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public func await<T>(_ futures: Future<T> ...) {
    assert(!Thread.isMainThread, "await will block main thread")
    if #available(iOS 10.0, *), #available(watchOSApplicationExtension 3.0, *), #available(OSX 10.12, *) {
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

internal extension DispatchQueue {

    func futureAsync<T, V>(execute work: @escaping (T) throws -> V) -> (T) -> Future<V> {

        return { (parameter: T) -> Future<V> in
            let promise = Promise<V>()
            self.async {
                promise.resolveWith { try work(parameter) }
            }
            return promise.future
        }
    }

    func futureSync<T, V>(execute work: @escaping (T) throws -> V) -> (T) -> Future<V> {

        return { (parameter: T) -> Future<V> in
            let promise = Promise<V>()
            if Thread.isMainThread {
                 promise.resolveWith { try work(parameter) }
            } else {
                self.sync {
                    promise.resolveWith { try work(parameter) }
                }
            }
            return promise.future
        }
    }
}
