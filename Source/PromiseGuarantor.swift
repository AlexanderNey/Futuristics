//
//  PromiseGuarantor.swift
//  PromiseME
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public class PromiseGuarantor<T> {
    public let promise = Promise<T>()
    
    public var isPending: Bool  {
        if case .Pending = promise.state {
            return true
        }
        return false
    }
    
    public init() { }
    
    public func reject(error: ErrorType) -> Promise<T> {
        self.promise.reject(error)
        return self.promise
    }
    
    public func fulfill(value: T) -> Promise<T> {
        self.promise.fulfill(value)
        return self.promise
    }
    
    public func resolve(f: Void throws -> T) {
        promise.resolve(f)
    }
    
    /**
    Experimental - use with defer
    */
    public func ensureResolution() {
        assert(!self.isPending, "Guarantor was not resolved")
    }
}