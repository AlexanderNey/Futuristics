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

fileprivate enum FutureCompletionHandler<T> {
    case success(task: (T) -> Void, queue: DispatchQueue)
    case failure(task: (Error) -> Void, queue: DispatchQueue)
    case finally(task: () -> Void, queue: DispatchQueue)
}

public enum FutureError : Error {
    case stillPending
}

public final class Future<T> {

    private let futureIdentifierKey = DispatchSpecificKey<ObjectIdentifier>()

    fileprivate let syncQueue: DispatchQueue
    
    internal var state: FutureState<T> = .pending {
        willSet {
            guard case .pending = state else {
                assertionFailure("Future state can not be changed as it is \(state) already")
                return
            }
        }
    }
    
    fileprivate var stateHandlers: [FutureCompletionHandler<T>] = []
    
    internal init() {
        self.syncQueue = DispatchQueue(label: "com.futuristics.future-queue")
        let identifier = ObjectIdentifier(self)
        self.syncQueue.setSpecific(key: futureIdentifierKey, value: identifier)
    }
    
    public func result() throws -> T {
        switch state {
        case .pending:
            throw FutureError.stillPending
        case .rejected(let error):
            throw error
        case .fulfilled(let result):
            return result
        }
    }
    
    internal func fulfill(_ value: T) {
        guard case .pending = state else { return }
        self.syncQueue.sync { state = .fulfilled(value) }
        self.syncQueue.async {
            self.executeDeferedCompletionHandlers()
        }
    }
    
    internal func reject(_ error: Error) {
        guard case .pending = state else { return }
        self.syncQueue.sync { state = .rejected(error) }
        self.syncQueue.async {
            self.executeDeferedCompletionHandlers()
        }
    }
    
    internal func resolveWith(_ f: () throws -> T) {
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
        self.stateHandlers.forEach(executeCompletionHandler)
        self.stateHandlers = []
    }

    fileprivate func executeCompletionHandler(_ handler: FutureCompletionHandler<T>) {
        switch (handler, state) {
        case (.success(let successHandler, let queue), .fulfilled(let value)):
            queue.async { successHandler(value) }
        case (.failure(let failureHandler, let queue), .rejected(let error)):
            queue.async { failureHandler(error) }
        case (.finally(let finalHandler, let queue), _) where !self.state.isPending:
            queue.async { finalHandler() }
        default: break
        }
    }
    
    fileprivate func deferCompletionHandler(_ handler: FutureCompletionHandler<T>) {
        stateHandlers.append(handler)
    }
    
    @discardableResult
    public func onSuccess(on queue: DispatchQueue = DispatchQueue.main,
                          successHandler: @escaping (T) -> Void) -> Future<T> {

        syncQueue.async {
            let completionHandler = FutureCompletionHandler.success(task: successHandler, queue: queue)
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
    public func onFailure(on queue: DispatchQueue = DispatchQueue.main,
                          failureHandler: @escaping (Error) -> Void) -> Future<T> {

        self.syncQueue.async {
            let completionHandler = FutureCompletionHandler<T>.failure(task: failureHandler, queue: queue)
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
    public func finally(on queue: DispatchQueue = DispatchQueue.main,
                        handler: @escaping () -> Void) -> Future<T> {
        syncQueue.async {
            let completionHandler = FutureCompletionHandler<T>.finally(task: handler, queue: queue)
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
