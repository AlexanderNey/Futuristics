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
        
        let expectExecutionOnMainThread = expectation(description: "runs on main thread")
        
        let somefunction = onMainQueue {
            if Thread.isMainThread {
                expectExecutionOnMainThread.fulfill()
            }
        }

        DispatchQueue.global(qos: .userInteractive).async {
            _ = somefunction()
        }
        
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testMainQueueSynch() {
        
        let expectExecutionOnMainThread = expectation(description: "runs on main thread")
        var imediateExecution = false
        let somefunction = onMainQueue { 
            imediateExecution = true
            if Thread.isMainThread {
                expectExecutionOnMainThread.fulfill()
            }
        }
        
        _ = somefunction()
        XCTAssertTrue(imediateExecution)
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testBackgroundQueueAsynch() {
        
        let expectExecutionOnBackgroundQueue = expectation(description: "runs on background queue")
        
        let somefunction = onBackgroundQueue {
            if !Thread.isMainThread {
                expectExecutionOnBackgroundQueue.fulfill()
            }
        }
        
        DispatchQueue.main.async {
            _ = somefunction()
        }
        
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testAsynchOnCustomQueue() {
    
        let queue = DispatchQueue(label: "testQueue", attributes: [])
       
        let expectExecutionOnCustomQueue = expectation(description: "runs on background queue")
        
        let somefunction = onQueue(queue)() { () -> Void in
            let queueLabel = String(validatingUTF8: __dispatch_queue_get_label(nil))
            if queueLabel == "testQueue"  {
                expectExecutionOnCustomQueue.fulfill()
            }
        }
        
        _ = somefunction()
        
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testAwaitSinglePromiseImediateResult() {
        let somefunction = { () -> Future<String> in
            let promise = Promise<String>()
            promise.fulfill("done")
            return promise.future
        }
        let future = somefunction()
        
        let awaitExpectation = expectation(description: "await on some background queue")
        
        onBackgroundQueue {
            await(future)
            awaitExpectation.fulfill()
        }()
        
        waitForExpectationsWithDefaultTimeout()

        
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
        
        let awaitExpectation = expectation(description: "await on some background queue")
        
        onBackgroundQueue {
            await(promiseA, promiseB)
            awaitExpectation.fulfill()
        }()
        
        waitForExpectationsWithDefaultTimeout()
        
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
