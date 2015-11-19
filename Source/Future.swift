//
//  Future.swift
//  Futuristics
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


// FIXME: had to move this out of the Future class as private static stored properties are not supported in generic classes yet
private var FutureCounter = 0

public class Future<T> {
    
    private let syncQueue: dispatch_queue_t!
    
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
                var stateHandlersSnapshot: [FutureCompletionHandler<T>]! = nil
                dispatch_sync(self.syncQueue) {
                    stateHandlersSnapshot = self.stateHandlers
                }
                stateHandlersSnapshot.forEach { self.executeCompletionHandler($0) }
                dispatch_sync(self.syncQueue) {
                    self.stateHandlers = []
                }
            default: break
            }
        }
    }
    
    private var stateHandlers: [FutureCompletionHandler<T>] = []
    
    internal init() {
        FutureCounter = FutureCounter &+ 1
        let queueName = "com.futuristics.future.queue\(FutureCounter)"
        self.syncQueue = dispatch_queue_create(queueName, DISPATCH_QUEUE_SERIAL)
    }
    
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
    
    private func deferCompletionHandler(handler: FutureCompletionHandler<T>) {
        dispatch_sync(self.syncQueue) {
            self.stateHandlers.append(handler)
        }
    }
    
    public func onSuccess(context: ExecutionContext = defaultExecutionContext, successHandler: T -> Void) -> Future<T> {
        let completionHandler = FutureCompletionHandler.Success(task: successHandler, context: context)
        switch self.state {
        case .Pending:
            self.deferCompletionHandler(completionHandler)
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
            self.deferCompletionHandler(completionHandler)
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
            self.deferCompletionHandler(completionHandler)
        default:
            self.executeCompletionHandler(completionHandler)
        }
        return self
    }
}