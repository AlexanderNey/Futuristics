//
//  Promise.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public final class Promise<T> {

    public let future = Future<T>()
    
    public var isPending: Bool  {
        if case .pending = future.state {
            return true
        }
        return false
    }
    
    public init() { }

    @discardableResult
    public func reject(_ error: Error) -> Future<T> {
        self.future.reject(error)
        return self.future
    }

    @discardableResult
    public func fulfill(_ value: T) -> Future<T> {
        self.future.fulfill(value)
        return self.future
    }

    public func resolveWith(_ f: () throws -> T) {
        future.resolveWith(f)
    }
    
    /**
    Experimental - use with defer
    */
    public func ensureResolution() {
        assert(!self.isPending, "Promise was not resolved")
    }
}
