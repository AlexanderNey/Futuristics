//
//  Promise.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public class Promise<T> {
    public let future = Future<T>()
    
    public var isPending: Bool  {
        if case .Pending = future.state {
            return true
        }
        return false
    }
    
    public init() { }
    
    public func reject(error: ErrorType) -> Future<T> {
        self.future.reject(error)
        return self.future
    }
    
    public func fulfill(value: T) -> Future<T> {
        self.future.fulfill(value)
        return self.future
    }
    
    public func resolveWith(f: Void throws -> T) {
        future.resolveWith(f)
    }
    
    /**
    Experimental - use with defer
    */
    public func ensureResolution() {
        assert(!self.isPending, "Promise was not resolved")
    }
}