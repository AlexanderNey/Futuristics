//
//  AsynchronousTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
@testable import Futuristics


enum TestError: Error {
    case someError
    case anotherError
}


func ordinaryFunction() -> Void { }
func throwingFunction() throws -> Void { throw TestError.anotherError }

class AsynchronousTests : XCTestCase {
    
    
    func testMainQueueAsynch() {
        
        let expectExecutionOnMainThread = AsynchTestExpectation("runs on main thread")
        
        let somefunction = onMainQueue {
            if Thread.isMainThread {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async {
            somefunction()
        }
        
        expectExecutionOnMainThread.waitForExpectationsWithTimeout()
    }
    
    func testMainQueueSynch() {
        
        let expectExecutionOnMainThread = AsynchTestExpectation("runs on main thread")
        var imediateExecution = false
        let somefunction = onMainQueue { 
            imediateExecution = true
            if Thread.isMainThread {
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
            if !Thread.isMainThread {
                expectExecutionOnBackgroundQueue.fulfill()
            }
        }
        
        DispatchQueue.main.async {
            somefunction()
        }
        
        expectExecutionOnBackgroundQueue.waitForExpectationsWithTimeout()
    }
    
    func testAsynchOnCustomQueue() {
    
        let queue = DispatchQueue(label: "testQueue", attributes: [])
       
        let expectExecutionOnCustomQueue = AsynchTestExpectation("runs on background queue")
        
        let somefunction = onQueue(queue)() { () -> Void in
            let queueLabel = String(validatingUTF8: DISPATCH_CURRENT_QUEUE_LABEL.label)
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

        
        if case .fulfilled(let value) = future.state {
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
        case (.fulfilled(let valueA), .fulfilled(let valueB)):
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
