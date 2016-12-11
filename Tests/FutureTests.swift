//
//  FutureTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 04/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
@testable import Futuristics


class FutureTests: XCTestCase {

    enum TestError: Error {
        case someError
        case anotherError
    }
    
    func testFulfill() {
        let future = Future<String>()
        
        if case .pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        future.fulfill("test")
        
        if case .fulfilled(let value) = future.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(future.state)")
        }
    }
    
    func testReject() {
        let future = Future<String>()
        
        if case .pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        future.reject(TestError.anotherError)
        
        if case .rejected(let error) = future.state, error as? TestError == TestError.anotherError  {
        } else {
            XCTFail("Future should be rejected with error \(TestError.anotherError) but was \(future.state)")
        }
    }
    
    func testMultipleFulfillmentRejectment() {
        let fulfilledPromise = Future<String>()
        fulfilledPromise.fulfill("test")
        fulfilledPromise.fulfill("testA")
        fulfilledPromise.reject(TestError.anotherError)
        
        if case .fulfilled(let value) = fulfilledPromise.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(fulfilledPromise.state)")
        }
        
        let rejectedPromise = Future<String>()
        rejectedPromise.reject(TestError.someError)
        rejectedPromise.fulfill("test")
        
        if case .rejected(let error) = rejectedPromise.state, error as? TestError == TestError.someError  {
        } else {
            XCTFail("Future should be rejected with error \(TestError.someError) but was \(rejectedPromise.state)")
        }
    }
    
    func testFulfillHandler() {
        let future = Future<String>()
        let handlerExpectation = AsynchTestExpectation("Success handler called")
        
        future.onSuccess { value in
            XCTAssertEqual(value, "test")
            handlerExpectation.fulfill()
        }
        
        future.fulfill("test")
        
        handlerExpectation.waitForExpectationsWithTimeout()
    }
    
    func testFulfillMultipleHandler() {
        let future = Future<String>()
        
        let successExpectation = AsynchTestExpectation("Success handler called")
        let secondSuccessExpectation = AsynchTestExpectation("Second success handler called")
        let afterFulfillSuccessExpectation = AsynchTestExpectation("After fulfillment success handler called")
        let finallyExpectation = AsynchTestExpectation("Finally  called")
        let afterFulfillFinallyExpectation = AsynchTestExpectation("After fulfillment finally called")
        
        future.onSuccess { value in
            XCTAssertEqual(value, "test")
            successExpectation.fulfill()
        }.onFailure { _ in
            XCTFail()
        }.onSuccess { value in
            XCTAssertEqual(value, "test")
            secondSuccessExpectation.fulfill()
        }.finally {
            finallyExpectation.fulfill()
        }
        
        XCTAssertTrue(future.state.isPending)
        
        future.fulfill("test")
        
        XCTAssertFalse(future.state.isPending)
        
        future.finally {
           afterFulfillFinallyExpectation.fulfill()
        }.onSuccess { value in
            XCTAssertEqual(value, "test")
            afterFulfillSuccessExpectation.fulfill()
        }.onFailure { _ in
            XCTFail()
        }
    
        successExpectation.waitForExpectationsWithTimeout()
        secondSuccessExpectation.waitForExpectationsWithTimeout()
        afterFulfillSuccessExpectation.waitForExpectationsWithTimeout()
        finallyExpectation.waitForExpectationsWithTimeout()
        afterFulfillFinallyExpectation.waitForExpectationsWithTimeout()
    }
    
    func testRejectMultipleHandler() {
        let future = Future<String>()
        
        let failureExpectation = AsynchTestExpectation("Failure handler called")
        let afterFulfillFailureExpectation = AsynchTestExpectation("After fulfillment failure handler called")
        let finallyExpectation = AsynchTestExpectation("Finally  called")
        let afterFulfillFinallyExpectation = AsynchTestExpectation("After fulfillment finally called")
        
        future.onSuccess { value in
                XCTFail()
            }.onFailure { _ in
                failureExpectation.fulfill()
            }.onSuccess { value in
                XCTFail("second success block was not expected to be called")
            }.finally {
                finallyExpectation.fulfill()
        }
        
        XCTAssertTrue(future.state.isPending)
        
        future.reject(TestError.someError)
        
         XCTAssertFalse(future.state.isPending)
        
        future.finally {
            afterFulfillFinallyExpectation.fulfill()
            }.onSuccess { value in
                XCTFail()
            }.onFailure { _ in
                afterFulfillFailureExpectation.fulfill()
        }
        
        failureExpectation.waitForExpectationsWithTimeout()
        afterFulfillFailureExpectation.waitForExpectationsWithTimeout()
        finallyExpectation.waitForExpectationsWithTimeout()
        afterFulfillFinallyExpectation.waitForExpectationsWithTimeout()
    }
    
    func testResolveRejectionWithThrowable() {
        
        func willThrow() throws -> String {
            throw TestError.someError
        }
        
        let future = Future<String>()
        
        if case .pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }

        future.resolveWith { try willThrow() }
        
        if case .rejected(let error) = future.state, error as? TestError == TestError.someError  {
        } else {
            XCTFail("Future should be rejected with error \(TestError.anotherError) but was \(future.state)")
        }
    }
    
    func testResolveFulfillWithThrowable() {
        
        func willNotThrow() throws -> String {
            return "test"
        }
        
        let future = Future<String>()
        
        if case .pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        future.resolveWith { try willNotThrow() }
        
        if case .fulfilled(let value) = future.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(future.state)")
        }
    }


    func testSuccessDefaultContext() {
        
        let future = Future<Void>()
        
        let preFulfillExpectation = AsynchTestExpectation("Pre fulfill success should execute on background thread")
        
        future.onSuccess {
            if Thread.isMainThread {
                preFulfillExpectation.fulfill()
            } else {
                let queueLabel = String(validatingUTF8: __dispatch_queue_get_label(nil))
                XCTFail("wrong queue \(queueLabel)")
            }
        }
        
        let dispatchTime = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global(qos: .default).asyncAfter(deadline: dispatchTime) {
            future.fulfill()
        }
        
        
        preFulfillExpectation.waitForExpectationsWithTimeout()
        let postFulfillExpectation = AsynchTestExpectation("Post fulfill success should execute on main thread")
        
        future.onSuccess {
            if Thread.isMainThread {
                postFulfillExpectation.fulfill()
            } else {
                let queueLabel = String(validatingUTF8: __dispatch_queue_get_label(nil))
                XCTFail("wrong queue \(queueLabel)")
            }
        }
        
        postFulfillExpectation.waitForExpectationsWithTimeout()
    }

    func testSuccessCustomContext() {
        
        let future = Future<Void>()
        
        let preFulfillExpectation = AsynchTestExpectation("Pre fulfill success should execute on main thread")
        
        future.onSuccess(on: DispatchQueue.main) {
            if Thread.isMainThread {
                preFulfillExpectation.fulfill()
            }
        }
        
        let dispatchTime = DispatchTime.now() + Double(Int64(0.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.global(qos: .default).asyncAfter(deadline: dispatchTime) {
            future.fulfill()
        }
        
        preFulfillExpectation.waitForExpectationsWithTimeout()
        
        let postFulfillExpectation = AsynchTestExpectation("Post fulfill success should execute on background thread")
        
        future.onSuccess(on: DispatchQueue.global()) {
            if !Thread.isMainThread {
                postFulfillExpectation.fulfill()
            }
        }
        
        postFulfillExpectation.waitForExpectationsWithTimeout()
    }

    
    func testBurteforceAddCompletionBlocksOnMainQueueFulfillFutureOnCustomQueue() {
       
        for _ in 1...100 {
            let future = Future<Void>()
            
            let preFulfillExpectation = AsynchTestExpectation("Bruteforce")
            
            let dispatchQueue = DispatchQueue(label: "custom serial queue", attributes: [])
            
            var successExecuted = 0
            var finallyExecuted = 0
            for i in  1...50 {
                if i == 25 {
                    dispatchQueue.async {
                        future.fulfill()
                    }
                }
                future.onSuccess {
                    successExecuted += 1
                    if successExecuted == 50 && finallyExecuted == 50 {
                        preFulfillExpectation.fulfill()
                    }
                }.finally {
                    finallyExecuted += 1
                    if successExecuted == 50 && finallyExecuted == 50 {
                        preFulfillExpectation.fulfill()
                    }
                }
            }
           
            preFulfillExpectation.waitForExpectationsWithTimeout()
        }
    }
    
    func testBurteforceAddCompletionBlocksOnMainQueueFulfillFutureOnMainQueue() {
        
        for _ in 1...100 {
            let future = Future<Void>()
            
            let preFulfillExpectation = AsynchTestExpectation("Bruteforce")
            
            var successExecuted = 0
            var finallyExecuted = 0
            for i in  1...50 {
                if i == 25 {
                    DispatchQueue.main.async {
                        future.fulfill()
                    }
                }
                future.onSuccess {
                    successExecuted += 1
                    if successExecuted == 50 && finallyExecuted == 50 {
                        preFulfillExpectation.fulfill()
                    }
                    }.finally {
                        finallyExecuted += 1
                        if successExecuted == 50 && finallyExecuted == 50 {
                            preFulfillExpectation.fulfill()
                        }
                }
            }
            
            preFulfillExpectation.waitForExpectationsWithTimeout()
        }
    }
    
    func testBurteforceAddCompletionBlocksOnRandomCustomQueueFulfillFutureOnMainQueue() {
        
        for _ in 1...100 {
            let future = Future<Void>()
            
            let preFulfillExpectation = AsynchTestExpectation("Bruteforce")
            
            var successExecuted = 0
            var finallyExecuted = 0
            for i in  1...50 {
                if i == 25 {
                    future.fulfill()
                }
                let dispatchQueue = DispatchQueue(label: "custom serial queue \(i)", attributes: [])
                dispatchQueue.async {
                    future.onSuccess {
                        successExecuted += 1
                        if successExecuted == 50 && finallyExecuted == 50 {
                            preFulfillExpectation.fulfill()
                        }
                    }
                }
                _ = dispatchQueue.sync {
                    future.finally {
                        finallyExecuted += 1
                        if successExecuted == 50 && finallyExecuted == 50 {
                            preFulfillExpectation.fulfill()
                        }
                    }
                }
            }
            
            preFulfillExpectation.waitForExpectationsWithTimeout()
        }
    }

}
