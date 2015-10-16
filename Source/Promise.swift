//
//  Promise.swift
//  PromiseME
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public enum PromiseState<T> {
    case Pending, Fulfilled(T), Rejected(ErrorType)
    
    public var isPending: Bool  {
        if case .Pending = self {
            return true
        }
        return false
    }
}

public typealias ExecutionContext = (Void throws -> Void) -> (Void -> Promise<Void>)


private func defaultExecutionContext(task: Void throws -> Void) -> (Void -> Promise<Void>) {
    return {
        let promise = Promise<Void>()
        promise.resolve { try task() }
        return promise
    }
}

private enum PromiseStateHandler<T> {
    case Success(task: T -> Void, context: ExecutionContext)
    case Failure(task: ErrorType -> Void, context: ExecutionContext)
    case Finally(task: Void -> Void, context: ExecutionContext)
}


public class Promise<T> {
    
    // TODO:
    //private let sync_queue = dispatch_queue_create(nil, nil)
    
    public internal(set) var state: PromiseState<T> = .Pending {
        willSet {
            guard case .Pending = self.state else {
                assertionFailure("Promise state can not be changed as it is \(self.state) already")
                return
            }
        }
        
        didSet {
            switch (self.state) {
            case .Rejected(_): fallthrough
            case .Fulfilled(_):
                
                self.stateHandlers.forEach { self.executeStateHandler($0) }
                self.stateHandlers = []
            default: break
            }
        }
    }
    
    private var stateHandlers: [PromiseStateHandler<T>] = []
    
    internal init() { }
    
    internal func fulfill(value: T) {
        guard case .Pending = self.state else { return }
        self.state = .Fulfilled(value)
    }
    
    internal func reject(error: ErrorType) {
        guard case .Pending = self.state else { return }
        self.state = .Rejected(error)
    }
    
    internal func resolve(f: Void throws -> T) {
        do {
            self.fulfill(try f())
        } catch {
            self.reject(error)
        }
    }
    
    internal func correlate<U>(promise: Promise<U>, _ transform: U -> T) {
        promise.onSuccess {
            self.fulfill(transform($0))
        }.onFailure {
            self.reject($0)
        }
    }
    
    private func executeStateHandler(handler: PromiseStateHandler<T>) {
        switch (handler, self.state) {
        case (.Success(let successHandler, let context), .Fulfilled(let value)):
            context { successHandler(value) }()
        case (.Failure(let failureHandler, let context), .Rejected(let error)):
            context { failureHandler(error) }()
        case (.Finally(let finalHandler, let context), _) where !self.state.isPending:
            context { finalHandler() }()
        default: break
        }
    }
    
    public func onSuccess(context: ExecutionContext = defaultExecutionContext, successHandler: T -> Void) -> Promise<T> {
        let stateHandler = PromiseStateHandler.Success(task: successHandler, context: context)
        switch self.state {
        case .Pending:
            self.stateHandlers.append(stateHandler)
        case .Fulfilled(_):
            self.executeStateHandler(stateHandler)
        default:
            break
        }
        return self
    }
    
    public func onFailure(context: ExecutionContext = defaultExecutionContext, failureHandler: ErrorType -> Void) -> Promise<T> {
        let stateHandler = PromiseStateHandler<T>.Failure(task: failureHandler, context: context)
        switch self.state {
        case .Pending:
            self.stateHandlers.append(stateHandler)
        case .Rejected(_):
            self.executeStateHandler(stateHandler)
        default:
            break
        }
        return self
    }
    
    public func finally(context: ExecutionContext = defaultExecutionContext, handler: Void -> Void) -> Promise<T> {
        let stateHandler = PromiseStateHandler<T>.Finally(task: handler, context: context)
        switch self.state {
        case .Pending:
            self.stateHandlers.append(stateHandler)
        default:
            self.executeStateHandler(stateHandler)
        }
        return self
    }
}