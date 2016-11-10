//
//  Future.swift
//  Futuristics
//
//  Created by Alexander Ney on 03/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


internal enum FutureState<T> {
    case pending, fulfilled(T), rejected(Error)
    
    var isPending: Bool  {
        if case .pending = self {
            return true
        }
        return false
    }
}

public typealias ExecutionContext = (_ task: (Void) throws -> Void) -> ((Void) -> Future<Void>)


let defaultExecutionContext: ExecutionContext = onMainQueue

private enum FutureCompletionHandler<T> {
    case success(task: (T) -> Void, context: ExecutionContext)
    case failure(task: (Error) -> Void, context: ExecutionContext)
    case finally(task: (Void) -> Void, context: ExecutionContext)
}


// FIXME: had to move this out of the Future class as private static stored properties are not supported in generic classes yet
private var FutureCounter = 0

public enum FutureError : Error {
    case futureStillPending
}

open class Future<T> {
    
    fileprivate let syncQueue: DispatchQueue!
    
    internal var state: FutureState<T> = .pending {
        willSet {
            guard case .pending = self.state else {
                assertionFailure("Future state can not be changed as it is \(self.state) already")
                return
            }
        }
    }
    
    fileprivate var stateHandlers: [FutureCompletionHandler<T>] = []
    
    internal init() {
        FutureCounter = FutureCounter &+ 1
        let queueName = "com.futuristics.future-queue\(FutureCounter)"
        self.syncQueue = DispatchQueue(label: queueName, attributes: [])
    }
    
    open func getResult() throws -> T {
        switch self.state {
        case .pending:
            throw FutureError.futureStillPending
        case .rejected(let error):
            throw error
        case .fulfilled(let result):
            return result
        }
    }
    
    internal func fulfill(_ value: T) {
        guard case .pending = self.state else { return }
        self.syncQueue.sync { self.state = .fulfilled(value) }
        self.syncQueue.async {
            self.executeDeferedCompletionHandlers()
        }
    }
    
    internal func reject(_ error: Error) {
        guard case .pending = self.state else { return }
        self.syncQueue.sync { self.state = .rejected(error) }
        self.syncQueue.async {
            self.executeDeferedCompletionHandlers()
        }
    }
    
    internal func resolveWith(_ f: (Void) throws -> T) {
        do {
            self.fulfill(try f())
        } catch {
            self.reject(error)
        }
    }
    
    internal func correlate<U>(_ future: Future<U>, _ transform: @escaping (U) -> T) {
        future.onSuccess {
            self.fulfill(transform($0))
        }.onFailure {
            self.reject($0)
        }
    }
    
    fileprivate func executeDeferedCompletionHandlers() {
        self.stateHandlers.forEach { self.executeCompletionHandler($0) }
        self.stateHandlers = []
    }

    fileprivate func executeCompletionHandler(_ handler: FutureCompletionHandler<T>) {
        switch (handler, self.state) {
        case (.success(let successHandler, let context), .fulfilled(let value)):
            _ = context { successHandler(value) }()
        case (.failure(let failureHandler, let context), .rejected(let error)):
            _ = context { failureHandler(error) }()
        case (.finally(let finalHandler, let context), _) where !self.state.isPending:
            _ = context { finalHandler() }()
        default: break
        }
    }
    
    fileprivate func deferCompletionHandler(_ handler: FutureCompletionHandler<T>) {
        self.stateHandlers.append(handler)
    }
    
    @discardableResult
    open func onSuccess(_ context: @escaping ExecutionContext = defaultExecutionContext, successHandler: @escaping (T) -> Void) -> Future<T> {
        self.syncQueue.async {
            let completionHandler = FutureCompletionHandler.success(task: successHandler, context: context)
            switch self.state {
            case .pending:
                self.deferCompletionHandler(completionHandler)
            case .fulfilled(_):
                self.executeCompletionHandler(completionHandler)
            default:
                break
            }
        }
        return self
    }

    @discardableResult
    open func onFailure(_ context: @escaping ExecutionContext = defaultExecutionContext, failureHandler: @escaping (Error) -> Void) -> Future<T> {
        self.syncQueue.async {
            let completionHandler = FutureCompletionHandler<T>.failure(task: failureHandler, context: context)
            switch self.state {
            case .pending:
                self.deferCompletionHandler(completionHandler)
            case .rejected(_):
                self.executeCompletionHandler(completionHandler)
            default:
                break
            }
        }
        return self
    }

    @discardableResult
    open func finally(_ context: @escaping ExecutionContext = defaultExecutionContext, handler: @escaping (Void) -> Void) -> Future<T> {
        self.syncQueue.async {
            let completionHandler = FutureCompletionHandler<T>.finally(task: handler, context: context)
            switch self.state {
            case .pending:
                self.deferCompletionHandler(completionHandler)
            default:
                self.executeCompletionHandler(completionHandler)
            }
        }
        return self
    }
}
