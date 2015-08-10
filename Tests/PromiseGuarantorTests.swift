//
//  PromiseGuarantorTests.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import PromiseME


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

class PromiseGuarantorTests : XCTestCase {
    
    func testFulfill() {
        let promiseGuarantor = PromiseGuarantor<String>()
        
        XCTAssertTrue(promiseGuarantor.isPending)
       
        if case .Pending = promiseGuarantor.promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promiseGuarantor.fulfill("test")
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Fulfilled(let value) = promiseGuarantor.promise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(promiseGuarantor.promise.state)")
        }
        
        promiseGuarantor.reject(AnError.AnotherError)
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Fulfilled(let value) = promiseGuarantor.promise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(promiseGuarantor.promise.state)")
        }
    }
    
    func testReject() {
        let promiseGuarantor = PromiseGuarantor<String>()
        
        XCTAssertTrue(promiseGuarantor.isPending)
        
        if case .Pending = promiseGuarantor.promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promiseGuarantor.reject(AnError.AnotherError)
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Rejected(let error) = promiseGuarantor.promise.state where error as? AnError == AnError.AnotherError  {
        } else {
            XCTFail("Promise should be rejected with error \(AnError.AnotherError) but was \(promiseGuarantor.promise.state)")
        }
        
        promiseGuarantor.fulfill("123")
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Rejected(let error) = promiseGuarantor.promise.state where error as? AnError == AnError.AnotherError  {
        } else {
            XCTFail("Promise should be rejected with error \(AnError.AnotherError) but was \(promiseGuarantor.promise.state)")
        }
    }
    
    func testResolveFulfill() {
        let promiseGuarantor = PromiseGuarantor<String>()
        
        XCTAssertTrue(promiseGuarantor.isPending)
        
        if case .Pending = promiseGuarantor.promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promiseGuarantor.resolve(somethingThatDontThrows)
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Fulfilled(let value) = promiseGuarantor.promise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(promiseGuarantor.promise.state)")
        }
        
        promiseGuarantor.reject(AnError.AnotherError)
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Fulfilled(let value) = promiseGuarantor.promise.state where value == "test"  {
        } else {
            XCTFail("Promise should be fulfilled with value 'test' but was \(promiseGuarantor.promise.state)")
        }
    }
    
    func testResolveRejected() {
        let promiseGuarantor = PromiseGuarantor<String>()
        
        XCTAssertTrue(promiseGuarantor.isPending)
        
        if case .Pending = promiseGuarantor.promise.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        promiseGuarantor.resolve { try somethingThatThrows() }
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Rejected(let error) = promiseGuarantor.promise.state where error as? AnError == AnError.SomeError  {
        } else {
            XCTFail("Promise should be rejected with error \(AnError.AnotherError) but was \(promiseGuarantor.promise.state)")
        }
        
        promiseGuarantor.fulfill("123")
        
        XCTAssertFalse(promiseGuarantor.isPending)
        
        if case .Rejected(let error) = promiseGuarantor.promise.state where error as? AnError == AnError.SomeError  {
        } else {
            XCTFail("Promise should be rejected with error \(AnError.AnotherError) but was \(promiseGuarantor.promise.state)")
        }
    }
    
}
