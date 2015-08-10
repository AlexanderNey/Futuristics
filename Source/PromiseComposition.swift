//
//  PromiseComposition.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


internal func bind<A, B>(closure: A -> Promise<B>) -> (Promise<A> -> Promise<B>) {
    return { promiseA in
        let promise = Promise<B>()
        promiseA.onSuccess { a in
            promise.correlate(closure(a), {$0})
        }.onFailure { error in
            promise.reject(error)
        }
        return promise
    }
}

public func >>> <A,B,C>(left: A -> Promise<B>, right: B -> Promise<C>) -> (A -> Promise<C>) {
    return { a in
        let rightBound = bind(right)
        return rightBound(left(a))
    }
}

public func |> <A,B>(left: A, right: A -> Promise<B>) -> Promise<B> {
    return right(left)
}

public func |> <A,B>(left: Promise<A>, right: A -> Promise<B>) -> Promise<B> {
    return bind(right)(left)
}