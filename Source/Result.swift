//
//  Result.swift
//  PromiseME
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public enum Result<T> {
    case Success(T)
    case Failure(ErrorType)
    
    public var error: ErrorType? {
        if case .Failure(let error) = self {
            return error
        } else {
            return nil
        }
    }
    
    public var value: T? {
        if case .Success(let value) = self {
            return value
        } else {
            return nil
        }
    }
    
    public init(@autoclosure _ f: Void throws -> T) {
        do {
            self = .Success(try f())
        } catch {
            self = .Failure(error)
        }
    }
    
    public func valueOrThrow() throws -> T {
        switch self {
        case .Success(let value):
            return value
        case .Failure(let error):
            throw error
        }
    }
}


// MARK: operator

public func ?? <T> (result: Result<T>, @autoclosure fallback: Void -> T) -> T {
    switch result {
    case .Success(let value):
        return value
    case .Failure(_):
        return fallback()
    }
}

public func ?? <T> (result: Result<T>, @autoclosure fallback: Void -> Result<T>) -> Result<T> {
    switch result {
    case .Success(_):
        return result
    case .Failure(_):
        return fallback()
    }
}