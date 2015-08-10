//
//  PromiseTests.swift
//  PromiseME
//
//  Created by Alexander Ney on 04/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
@testable import PromiseME


class PromiseTests: XCTestCase {

    enum TestError: ErrorType {
        case SomeError
        case AnotherError
    }
    
    func testFulfill() {
        let promise = Promise<String>()
        
        if case .Pending = promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.fulfill("test")
        
        if case .Fulfilled(let value) = promise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(promise.state)")
        }
    }
    
    func testReject() {
        let promise = Promise<String>()
        
        if case .Pending = promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.reject(TestError.AnotherError)
        
        if case .Rejected(let error) = promise.state where error as? TestError == TestError.AnotherError  {
        } else {
            XCTFail("Promise should be rejected with error \(TestError.AnotherError) but was \(promise.state)")
        }
    }
    
    func testMultipleFulfillmentRejectment() {
        let fulfilledPromise = Promise<String>()
        fulfilledPromise.fulfill("test")
        fulfilledPromise.fulfill("testA")
        fulfilledPromise.reject(TestError.AnotherError)
        
        if case .Fulfilled(let value) = fulfilledPromise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(fulfilledPromise.state)")
        }
        
        let rejectedPromise = Promise<String>()
        rejectedPromise.reject(TestError.SomeError)
        rejectedPromise.fulfill("test")
        
        if case .Rejected(let error) = rejectedPromise.state where error as? TestError == TestError.SomeError  {
        } else {
            XCTFail("Promise should be rejected with error \(TestError.SomeError) but was \(rejectedPromise.state)")
        }
    }
    
    func testFulfillHandler() {
        let promise = Promise<String>()
        let handlerExpectation = self.expectationWithDescription("Success handler called")
        
        promise.onSuccess { value in
            XCTAssertEqual(value, "test")
            handlerExpectation.fulfill()
        }
        
        promise.fulfill("test")
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    func testFulfillMultipleHandler() {
        let promise = Promise<String>()
        
        let successExpectation = self.expectationWithDescription("Success handler called")
        let secondSuccessExpectation = self.expectationWithDescription("Second success handler called")
        let afterFulfillSuccessExpectation = self.expectationWithDescription("After fulfillment success handler called")
        let finallyExpectation = self.expectationWithDescription("Finally  called")
        let afterFulfillFinallyExpectation = self.expectationWithDescription("After fulfillment finally called")
        
        promise.onSuccess { value in
            XCTAssertEqual(value, "test")
            successExpectation.fulfill()
        }.onFailure { _ in
            XCTFail()
        }.onSuccess { value in
            print("success")
            XCTAssertEqual(value, "test")
            secondSuccessExpectation.fulfill()
        }.finally {
            finallyExpectation.fulfill()
        }
        
        XCTAssertTrue(promise.state.isPending)
        
        promise.fulfill("test")
        
        XCTAssertFalse(promise.state.isPending)
        
        promise.finally {
           afterFulfillFinallyExpectation.fulfill()
        }.onSuccess { value in
            XCTAssertEqual(value, "test")
            afterFulfillSuccessExpectation.fulfill()
        }.onFailure { _ in
            XCTFail()
        }
    
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testRejectMultipleHandler() {
        let promise = Promise<String>()
        
        let failureExpectation = self.expectationWithDescription("Failure handler called")
        let afterFulfillFailureExpectation = self.expectationWithDescription("After fulfillment failure handler called")
        let finallyExpectation = self.expectationWithDescription("Finally  called")
        let afterFulfillFinallyExpectation = self.expectationWithDescription("After fulfillment finally called")
        
        promise.onSuccess { value in
                XCTFail()
            }.onFailure { _ in
                failureExpectation.fulfill()
            }.onSuccess { value in
                XCTFail("second success block was not expected to be called")
            }.finally {
                finallyExpectation.fulfill()
        }
        
        XCTAssertTrue(promise.state.isPending)
        
        promise.reject(TestError.SomeError)
        
         XCTAssertFalse(promise.state.isPending)
        
        promise.finally {
            afterFulfillFinallyExpectation.fulfill()
            }.onSuccess { value in
                XCTFail()
            }.onFailure { _ in
                afterFulfillFailureExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testResolveRejectionWithThrowable() {
        
        func willThrow() throws -> String {
            throw TestError.SomeError
        }
        
        let promise = Promise<String>()
        
        if case .Pending = promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }

        promise.resolve { try willThrow() }
        
        if case .Rejected(let error) = promise.state where error as? TestError == TestError.SomeError  {
        } else {
            XCTFail("Promise should be rejected with error \(TestError.AnotherError) but was \(promise.state)")
        }
    }
    
    func testResolveFulfillWithThrowable() {
        
        func willNotThrow() throws -> String {
            return "test"
        }
        
        let promise = Promise<String>()
        
        if case .Pending = promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.resolve { try willNotThrow() }
        
        if case .Fulfilled(let value) = promise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(promise.state)")
        }
    }


    func testSuccessDefaultContext() {
        
        let promise = Promise<Void>()
        
        let preFulfillExpectation = self.expectationWithDescription("Pre fulfill success should execute on background thread")
        
        promise.onSuccess {
            if !NSThread.isMainThread() {
                preFulfillExpectation.fulfill()
            }
        }
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            promise.fulfill()
        }
        
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
        let postFulfillExpectation = self.expectationWithDescription("Post fulfill success should execute on main thread")
        
        promise.onSuccess {
            if NSThread.isMainThread() {
                postFulfillExpectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    func testSuccessCustomContext() {
        
        let promise = Promise<Void>()
        
        let preFulfillExpectation = self.expectationWithDescription("Pre fulfill success should execute on main thread")
        
        promise.onSuccess(onMainQueue) {
            if NSThread.isMainThread() {
                preFulfillExpectation.fulfill()
            }
        }
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            promise.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
        
        let postFulfillExpectation = self.expectationWithDescription("Post fulfill success should execute on background thread")
        
        promise.onSuccess(onBackgroundQueue) {
            if !NSThread.isMainThread() {
                postFulfillExpectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

}