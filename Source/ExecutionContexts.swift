//
//  ExecutionContexts.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


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
            if Thread.isMainThread && self == DispatchQueue.main {
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
