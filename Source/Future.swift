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

public typealias ExecutionContext = (_ task: @escaping (Void) throws -> Void) -> ((Void) -> Future<Void>)


let defaultExecutionContext: ExecutionContext = onMainQueue

private enum FutureCompletionHandler<T> {
    case success(task: @escaping (T) -> Void, context: ExecutionContext)
    case failure(task: @escaping (Error) -> Void, context: ExecutionContext)
    case finally(task: @escaping (Void) -> Void, context: ExecutionContext)
}


// FIXME: had to move this out of the Future class as private static stored properties are not supported in generic classes yet
private var FutureCounter = 0

public enum FutureError : Error {
    case futureStillPending
}

public class Future<T> {
    
    private let syncQueue: DispatchQueue!
    
    internal var state: FutureState<T> = .pending {
        willSet {
            guard case .pending = self.state else {
                assertionFailure("Future state can not be changed as it is \(self.state) already")
                return
            }
        }
    }
    
    private var stateHandlers: [FutureCompletionHandler<T>] = []
    
    internal init() {
        FutureCounter = FutureCounter &+ 1
        let queueName = "com.futuristics.future-queue\(FutureCounter)"

        self.syncQueue = DispatchQueue(label: queueName)
    }
    
    public func getResult() throws -> T {
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
    
    private func executeDeferedCompletionHandlers() {
        self.stateHandlers.forEach { self.executeCompletionHandler($0) }
        self.stateHandlers = []
    }

    private func executeCompletionHandler(_ handler: FutureCompletionHandler<T>) {
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
    
    private func deferCompletionHandler(_ handler: FutureCompletionHandler<T>) {
        self.stateHandlers.append(handler)
    }
    
    
    @discardableResult
    public func onSuccess(_ context: ExecutionContext = defaultExecutionContext, successHandler: @escaping (T) -> Void) -> Future<T> {
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
    public func onFailure(_ context: ExecutionContext = defaultExecutionContext, failureHandler: @escaping (Error) -> Void) -> Future<T> {
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
    public func finally(_ context: ExecutionContext = defaultExecutionContext, handler: @escaping (Void) -> Void) -> Future<T> {
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
