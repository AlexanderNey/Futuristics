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
        
        let expectExecutionOnMainThread = AsynchTestExpectation("runs on main thread")
        
        let somefunction = onMainQueue {
            if NSThread.isMainThread() {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            somefunction()
        }
        
        expectExecutionOnMainThread.waitForExpectationsWithTimeout()
    }
    
    func testMainQueueSynch() {
        
        let expectExecutionOnMainThread = AsynchTestExpectation("runs on main thread")
        var imediateExecution = false
        let somefunction = onMainQueue { 
            imediateExecution = true
            if NSThread.isMainThread() {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        somefunction()
        XCTAssertTrue(imediateExecution)
        expectExecutionOnMainThread.waitForExpectationsWithTimeout()
    }
    
    func testBackgroundQueueAsynch() {
        
        let expectExecutionOnBackgroundQueue = AsynchTestExpectation("runs on background queue")
        
        let somefunction = onBackgroundQueue {
            if !NSThread.isMainThread() {
                expectExecutionOnBackgroundQueue.fulfill()
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            somefunction()
        }
        
        expectExecutionOnBackgroundQueue.waitForExpectationsWithTimeout()
    }
    
    func testAsynchOnCustomQueue() {
    
        let queue = dispatch_queue_create("testQueue", nil)
       
        let expectExecutionOnCustomQueue = AsynchTestExpectation("runs on background queue")
        
        let somefunction = onQueue(queue)() { () -> Void in
            let queueLabel = String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
            if queueLabel == "testQueue"  {
                expectExecutionOnCustomQueue.fulfill()
            }
        }
        
        somefunction()
        
        expectExecutionOnCustomQueue.waitForExpectationsWithTimeout()
    }
    
    func testAwaitSinglePromiseImediateResult() {
        let somefunction = { () -> Future<String> in
            let promise = Promise<String>()
            promise.fulfill("done")
            return promise.future
        }
        let future = somefunction()
        
        let awaitExpectation = AsynchTestExpectation("await on some background queue")
        
        onBackgroundQueue {
            await(future)
            awaitExpectation.fulfill()
        }()
        
        awaitExpectation.waitForExpectationsWithTimeout()

        
        if case .Fulfilled(let value) = future.state {
            XCTAssertEqual(value, "done")
        } else {
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
        
        let awaitExpectation = AsynchTestExpectation("await on some background queue")
        
        onBackgroundQueue {
            await(promiseA, promiseB)
            awaitExpectation.fulfill()
        }()
        
         awaitExpectation.waitForExpectationsWithTimeout()
        
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