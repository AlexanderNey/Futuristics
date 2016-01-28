//
//  CompletionHandlerTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 26/01/2016.
//  Copyright © 2016 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import Futuristics



class CompletionHandlerTests : XCTestCase {

    class TestOwner { }
    
    func delayedSuccessfulFunction() -> Future<Void> {
        let promise = Promise<Void>()
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            promise.fulfill()
        }
        return promise.future
    }
    
    func successfulFunction() -> Future<Void> {
        let promise = Promise<Void>()
        promise.fulfill()
        return promise.future
    }

    
    func testDelayedSuccessCompletionHandlerWithOwnership() {
        
        let fulfillExpectation = AsynchTestExpectation("execute success handler")
        let owner = TestOwner()
        delayedSuccessfulFunction().onSuccess(owner: owner) {
            fulfillExpectation.fulfill()
        }
        
        fulfillExpectation.waitForExpectationsWithTimeout()
    }
    
    func testDelayedSuccessCompletionHandlerWithInvalidatedOwnership() {
        
        let fulfillExpectation = AsynchTestExpectation("execute success handler")
        var owner: TestOwner? = TestOwner()
        weak var weakOwner = owner

        delayedSuccessfulFunction().onSuccess(owner: weakOwner) {
            fulfillExpectation.fulfill()
        }
        
        owner = nil
        
        fulfillExpectation.waitForExpectationsWithTimeout(mustFulfill: false)
    }
    
    
}
