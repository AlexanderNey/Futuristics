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


enum AnError: Error {
    case someError
    case anotherError
}

func somethingThatThrows() throws -> String {
    throw AnError.someError
}

func somethingThatDontThrows() throws -> String {
    return "test"
}

class PromiseTests : XCTestCase {
    
    func testFulfill() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
       
        if case .pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.fulfill("test")
        
        XCTAssertFalse(promise.isPending)
        
        if case .fulfilled(let value) = promise.future.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
        
        promise.reject(AnError.anotherError)
        
        XCTAssertFalse(promise.isPending)
        
        if case .fulfilled(let value) = promise.future.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
    }
    
    func testReject() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
        
        if case .pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.reject(AnError.anotherError)
        
        XCTAssertFalse(promise.isPending)
        
        if case .rejected(let error) = promise.future.state, error as? AnError == AnError.anotherError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.anotherError) but was \(promise.future.state)")
        }
        
        promise.fulfill("123")
        
        XCTAssertFalse(promise.isPending)
        
        if case .rejected(let error) = promise.future.state, error as? AnError == AnError.anotherError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.anotherError) but was \(promise.future.state)")
        }
    }
    
    func testResolveFulfill() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
        
        if case .pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.resolveWith(somethingThatDontThrows)
        
        XCTAssertFalse(promise.isPending)
        
        if case .fulfilled(let value) = promise.future.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
        
        promise.reject(AnError.anotherError)
        
        XCTAssertFalse(promise.isPending)
        
        if case .fulfilled(let value) = promise.future.state, value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(promise.future.state)")
        }
    }
    
    func testResolveRejected() {
        let promise = Promise<String>()
        
        XCTAssertTrue(promise.isPending)
        
        if case .pending = promise.future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promise.resolveWith { try somethingThatThrows() }
        
        XCTAssertFalse(promise.isPending)
        
        if case .rejected(let error) = promise.future.state, error as? AnError == AnError.someError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.anotherError) but was \(promise.future.state)")
        }
        
        promise.fulfill("123")
        
        XCTAssertFalse(promise.isPending)
        
        if case .rejected(let error) = promise.future.state, error as? AnError == AnError.someError  {
        } else {
            XCTFail("Future should be rejected with error \(AnError.anotherError) but was \(promise.future.state)")
        }
    }
    
}
