//
//  Promise.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


open class Promise<T> {
    open let future = Future<T>()
    
    open var isPending: Bool  {
        if case .pending = future.state {
            return true
        }
        return false
    }
    
    public init() { }
    
    open func reject(_ error: Error) -> Future<T> {
        self.future.reject(error)
        return self.future
    }
    
    open func fulfill(_ value: T) -> Future<T> {
        self.future.fulfill(value)
        return self.future
    }
    
    open func resolveWith(_ f: (Void) throws -> T) {
        future.resolveWith(f)
    }
    
    /**
    Experimental - use with defer
    */
    open func ensureResolution() {
        assert(!self.isPending, "Promise was not resolved")
    }
}
