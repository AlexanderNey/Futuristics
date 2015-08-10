//
//  AsynchronousTests.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import PromiseME


enum TestError: ErrorType {
    case SomeError
    case AnotherError
}


func ordinaryFunction() -> Void { }
func throwingFunction() throws -> Void { throw TestError.AnotherError }

class AsynchronousTests : XCTestCase {
    
    
    func testMainQueueAsynch() {
        
        let expectExecutionOnMainThread = self.expectationWithDescription("runs on main thread")
        
        let somefunction = onMainQueue { () -> Void in
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
        let somefunction = onMainQueue { () -> Void in
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
        let somefunction = onMainQueue(after: 2.0)() { () -> Void in
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
        
        let somefunction = onBackgroundQueue { () -> Void in
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
    
    func testAwaitPromiseDelayed() {
        let somefunction = onBackgroundQueue(after: 2)() { () -> String in
            return "done"
        }
        let promise = somefunction()
        await(promise)
        
        if case .Fulfilled(let value) = promise.state {
            XCTAssertEqual(value, "done")
        } else {
            XCTFail()
        }
    }

    
    func testAwaitPromiseImediately() {
        let somefunction = { () -> Promise<String> in
            let promiseGuarantor = PromiseGuarantor<String>()
            promiseGuarantor.fulfill("done")
            return promiseGuarantor.promise
        }
        let promise = somefunction()
        
        await(promise)
        
        if case .Fulfilled(let value) = promise.state {
            XCTAssertEqual(value, "done")
        } else {
            XCTFail()
        }
    }

}