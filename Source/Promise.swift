//
//  Future.swift
//  PromiseME
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public enum FutureState<T> {
    case Pending, Fulfilled(T), Rejected(ErrorType)
    
    public var isPending: Bool  {
        if case .Pending = self {
            return true
        }
        return false
    }
}

public typealias ExecutionContext = (task: Void throws -> Void) -> (Void -> Future<Void>)


let defaultExecutionContext: ExecutionContext = { (task: Void throws -> Void) -> (Void -> Future<Void>) in
    return {
        let future = Future<Void>()
        future.resolve { try task() }
        return future
    }
}

private enum FutureCompletionHandler<T> {
    case Success(task: T -> Void, context: ExecutionContext)
    case Failure(task: ErrorType -> Void, context: ExecutionContext)
    case Finally(task: Void -> Void, context: ExecutionContext)
}


public class Future<T> {
    
    // TODO:
    //private let sync_queue = dispatch_queue_create(nil, nil)
    
    public internal(set) var state: FutureState<T> = .Pending {
        willSet {
            guard case .Pending = self.state else {
                assertionFailure("Future state can not be changed as it is \(self.state) already")
                return
            }
        }
        
        didSet {
            switch (self.state) {
            case .Rejected(_): fallthrough
            case .Fulfilled(_):
                
                self.stateHandlers.forEach { self.executeCompletionHandler($0) }
                self.stateHandlers = []
            default: break
            }
        }
    }
    
    private var stateHandlers: [FutureCompletionHandler<T>] = []
    
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
    
    internal func correlate<U>(future: Future<U>, _ transform: U -> T) {
        future.onSuccess {
            self.fulfill(transform($0))
        }.onFailure {
            self.reject($0)
        }
    }
    
    private func executeCompletionHandler(handler: FutureCompletionHandler<T>) {
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
    
    public func onSuccess(context: ExecutionContext = defaultExecutionContext, successHandler: T -> Void) -> Future<T> {
        let completionHandler = FutureCompletionHandler.Success(task: successHandler, context: context)
        switch self.state {
        case .Pending:
            self.stateHandlers.append(completionHandler)
        case .Fulfilled(_):
            self.executeCompletionHandler(completionHandler)
        default:
            break
        }
        return self
    }
    
    public func onFailure(context: ExecutionContext = defaultExecutionContext, failureHandler: ErrorType -> Void) -> Future<T> {
        let completionHandler = FutureCompletionHandler<T>.Failure(task: failureHandler, context: context)
        switch self.state {
        case .Pending:
            self.stateHandlers.append(completionHandler)
        case .Rejected(_):
            self.executeCompletionHandler(completionHandler)
        default:
            break
        }
        return self
    }
    
    public func finally(context: ExecutionContext = defaultExecutionContext, handler: Void -> Void) -> Future<T> {
        let completionHandler = FutureCompletionHandler<T>.Finally(task: handler, context: context)
        switch self.state {
        case .Pending:
            self.stateHandlers.append(completionHandler)
        default:
            self.executeCompletionHandler(completionHandler)
        }
        return self
    }
}