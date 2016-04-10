//
//  PromiseTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
@testable import Futuristics


enum AnError: ErrorType {
    case SomeError
    case AnotherError
}

func somethingThatThrows() throws -> String {
    throw AnError.SomeError
}

func somethingThatDontThrows() throws -> String {
    return "test"
}

class PromiseTests : XCTestCase {
    
    func testFulfill() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
       
        if case .Pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.fulfill("test")
        
        XCTAssertFalse(promise.isPending)
        
        if case .Fulfilled(let value) = promise.future.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
        
        promise.reject(AnError.AnotherError)
        
        XCTAssertFalse(promise.isPending)
        
        if case .Fulfilled(let value) = promise.future.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
    }
    
    func testReject() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
        
        if case .Pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.reject(AnError.AnotherError)
        
        XCTAssertFalse(promise.isPending)
        
        if case .Rejected(let error) = promise.future.state where error as? AnError == AnError.AnotherError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.AnotherError) but was \(promise.future.state)")
        }
        
        promise.fulfill("123")
        
        XCTAssertFalse(promise.isPending)
        
        if case .Rejected(let error) = promise.future.state where error as? AnError == AnError.AnotherError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.AnotherError) but was \(promise.future.state)")
        }
    }
    
    func testResolveFulfill() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
        
        if case .Pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.resolveWith(somethingThatDontThrows)
        
        XCTAssertFalse(promise.isPending)
        
        if case .Fulfilled(let value) = promise.future.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
        
        promise.reject(AnError.AnotherError)
        
        XCTAssertFalse(promise.isPending)
        
        if case .Fulfilled(let value) = promise.future.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
    }
    
    func testResolveRejected() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
        
        if case .Pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.resolveWith { try somethingThatThrows() }
        
        XCTAssertFalse(promise.isPending)
        
        if case .Rejected(let error) = promise.future.state where error as? AnError == AnError.SomeError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.AnotherError) but was \(promise.future.state)")
        }
        
        promise.fulfill("123")
        
        XCTAssertFalse(promise.isPending)
        
        if case .Rejected(let error) = promise.future.state where error as? AnError == AnError.SomeError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.AnotherError) but was \(promise.future.state)")
        }
    }
    
}
