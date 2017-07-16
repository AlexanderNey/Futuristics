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

        let somefunction = DispatchQueue.main.futureAsync { (_: Void) -> Void in
            XCTAssertTrue(Thread.isMainThread)
            expectExecutionOnMainThread.fulfill()
        }

        _ = somefunction(())
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testMainQueueSynch() {
        
        let expectExecutionOnMainThread = expectation(description: "runs on main thread")
        var imediateExecution = false
        let somefunction = DispatchQueue.main.futureSync { (_: Void) -> Void in
            imediateExecution = true
            XCTAssertTrue(Thread.current.isMainThread)
            expectExecutionOnMainThread.fulfill()
        }
        
        _ = somefunction(())
        XCTAssertTrue(imediateExecution)
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testBackgroundQueueAsynch() {
        
        let expectExecutionOnBackgroundQueue = expectation(description: "runs on background queue")

        let somefunction = DispatchQueue.global(qos: .userInitiated).futureAsync { (_: Void) -> Void in
            XCTAssertFalse(Thread.current.isMainThread)
            expectExecutionOnBackgroundQueue.fulfill()
        }
        
        DispatchQueue.main.async {
            _ = somefunction(())
        }
        
        waitForExpectationsWithDefaultTimeout()
    }
    
    func testAsynchOnCustomQueue() {
    
        let queue = DispatchQueue(label: "testQueue", attributes: [])
       
        let expectExecutionOnCustomQueue = expectation(description: "runs on background queue")
        
        let somefunction = queue.futureAsync { () -> Void in
            let queueLabel = String(validatingUTF8: __dispatch_queue_get_label(nil))
            XCTAssertEqual(queueLabel, "testQueue")
            expectExecutionOnCustomQueue.fulfill()
        }
        
        _ = somefunction(())
        waitForExpectationsWithDefaultTimeout()
    }

    func testSynchOnCustomQueue() {

        let queue = DispatchQueue(label: "testQueue", attributes: [])

        let expectExecutionOnCustomQueue = expectation(description: "runs on background queue")
        var immediateExecution = false
        let somefunction = queue.futureSync { () -> Void in
            let queueLabel = String(validatingUTF8: __dispatch_queue_get_label(nil))
            immediateExecution = true
            XCTAssertEqual(queueLabel, "testQueue")
            expectExecutionOnCustomQueue.fulfill()
        }

        _ = somefunction(())
        XCTAssertTrue(immediateExecution)
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
        
        DispatchQueue.global(qos: .userInitiated).async {
            let result = try! future.await() as String
            XCTAssertEqual(result, "done")
            awaitExpectation.fulfill()
        }
        
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
    
        let futureA = someFunction()
        let futureB = someFunction()
        
        let awaitExpectation = expectation(description: "await on some background queue")
        
        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? futureA.await() as String
            _ = try? futureB.await() as String

            XCTAssertTrue(futureA.state.isFulfilled)
            XCTAssertTrue(futureB.state.isFulfilled)
            awaitExpectation.fulfill()
        }
        
        waitForExpectationsWithDefaultTimeout()
    }
}
