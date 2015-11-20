//
//  AsynchronousTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import Futuristics


enum TestError: ErrorType {
    case SomeError
    case AnotherError
}


func ordinaryFunction() -> Void { }
func throwingFunction() throws -> Void { throw TestError.AnotherError }

class AsynchronousTests : XCTestCase {
    
    
    func testMainQueueAsynch() {
        
        let expectExecutionOnMainThread = self.expectationWithDescription("runs on main thread")
        
        let somefunction = onMainQueue {
            if NSThread.isMainThread() {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            somefunction()
        }
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMainQueueSynch() {
        
        let expectExecutionOnMainThread = self.expectationWithDescription("runs on main thread")
        var imediateExecution = false
        let somefunction = onMainQueue { 
            imediateExecution = true
            if NSThread.isMainThread() {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        somefunction()
        XCTAssertTrue(imediateExecution)
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testMainQueueDelayedAsynch() {
        
        let expectExecutionOnMainThread = self.expectationWithDescription("runs on main thread")
        let startDate = NSDate()
        let somefunction = onMainQueue(after: 2.0)() {
            XCTAssertEqualWithAccuracy(startDate.timeIntervalSinceNow, -2.0, accuracy: 0.3, "expected to be executed with a 2 seconds delay")
            if NSThread.isMainThread() {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            somefunction()
        }
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testBackgroundQueueAsynch() {
        
        let expectExecutionOnBackgroundQueue = self.expectationWithDescription("runs on background queue")
        
        let somefunction = onBackgroundQueue {
            if !NSThread.isMainThread() {
                expectExecutionOnBackgroundQueue.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            somefunction()
        }
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testAsynchOnCustomQueue() {
    
        let queue = dispatch_queue_create("testQueue", nil)
       
        let expectExecutionOnCustomQueue = self.expectationWithDescription("runs on background queue")
        
        let somefunction = onQueue(queue)() { () -> Void in
            let queueLabel = String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
            if queueLabel == "testQueue"  {
                expectExecutionOnCustomQueue.fulfill()
            }
        }
        
        somefunction()
        
        self.waitForExpectationsWithTimeout(5, handler: nil)
    }
    
    func testAwaitSinglePromiseDelayed() {
        let somefunction = onBackgroundQueue(after: 1)() { () -> String in
            return "done"
        }
        let future = somefunction()
        
        let awaitExpectation = self.expectationWithDescription("await on some background queue")
        
        onBackgroundQueue {
            await(future)
            awaitExpectation.fulfill()
        }()
        
        self.waitForExpectationsWithTimeout(2, handler: nil)
        
        if case .Fulfilled(let value) = future.state {
            XCTAssertEqual(value, "done")
        } else {
            XCTFail()
        }
    }

    
    func testAwaitSinglePromiseImediateResult() {
        let somefunction = { () -> Future<String> in
            let promise = Promise<String>()
            promise.fulfill("done")
            return promise.future
        }
        let future = somefunction()
        
        let awaitExpectation = self.expectationWithDescription("await on some background queue")
        
        onBackgroundQueue {
            await(future)
            awaitExpectation.fulfill()
        }()
        
        self.waitForExpectationsWithTimeout(1, handler: nil)

        
        if case .Fulfilled(let value) = future.state {
            XCTAssertEqual(value, "done")
        } else {
            XCTFail()
        }
    }

    
    func testAwaitMultiplePromisesDelayed() {
        let someBackgroundfunctionA = onBackgroundQueue(after: 0.1)({ () -> String in
            return "doneA"
        })
        
        let someBackgroundfunctionB = onBackgroundQueue(after: 0.2)({ () -> String in
            return "doneB"
        })
        
        let promiseA = someBackgroundfunctionA()
        let promiseB = someBackgroundfunctionB()
        
        let awaitExpectation = self.expectationWithDescription("await on some background queue")
        
        onBackgroundQueue {
            await(promiseA, promiseB)
            awaitExpectation.fulfill()
        }()
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
        
        switch (promiseA.state, promiseB.state) {
        case (.Fulfilled(let valueA), .Fulfilled(let valueB)):
            XCTAssertEqual(valueA, "doneA")
            XCTAssertEqual(valueB, "doneB")
        default:
            XCTFail()
        }
    }
    
    func testAwaitMultiplePromisesImediateResult() {
        func someFunction() -> Future<String> {
            let promise = Promise<String>()
            promise.fulfill("done")
            return promise.future
        }
        
    
        let promiseA = someFunction()
        let promiseB = someFunction()
        
        let awaitExpectation = self.expectationWithDescription("await on some background queue")
        
        onBackgroundQueue {
            await(promiseA, promiseB)
            awaitExpectation.fulfill()
        }()
        
         self.waitForExpectationsWithTimeout(1, handler: nil)
        
        switch (promiseA.state, promiseB.state) {
        case (.Fulfilled(let valueA), .Fulfilled(let valueB)):
            XCTAssertEqual(valueA, "done")
            XCTAssertEqual(valueB, "done")
        default:
            XCTFail()
        }
    }
    
    /*
    func testBundleMultiplePromisesImediateResult() {
        func someFunction() -> Future<String> {
            let promise = Promise<String>()
            promise.fulfill("done")
            return promise.future
        }
        
        
        let promiseA = someFunction()
        let promiseB = someFunction()
        bundle(promiseA, promiseB)
        
        switch (promiseA.state, promiseB.state) {
        case (.Fulfilled(let valueA), .Fulfilled(let valueB)):
            XCTAssertEqual(valueA, "done")
            XCTAssertEqual(valueB, "done")
        default:
            XCTFail()
        }
    }*/


}