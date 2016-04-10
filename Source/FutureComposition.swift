//
//  FutureComposition.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


internal func bind<A, B>(closure: A -> Future<B>) -> (Future<A> -> Future<B>) {
    return { promiseA in
        let future = Future<B>()
        promiseA.onSuccess { a in
            future.correlate(closure(a), {$0})
        }.onFailure { error in
            future.reject(error)
        }
        return future
    }
}

public func >>> <A,B,C>(left: A -> Future<B>, right: B -> Future<C>) -> (A -> Future<C>) {
    return { a in
        let rightBound = bind(right)
        return rightBound(left(a))
    }
}

public func |> <A,B>(left: A, right: A -> Future<B>) -> Future<B> {
    return right(left)
}

public func |> <A,B>(left: Future<A>, right: A -> Future<B>) -> Future<B> {
    return bind(right)(left)
}