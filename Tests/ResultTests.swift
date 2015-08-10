//
//  ResultTests.swift
//  PromiseME
//
//  Created by Alexander Ney on 04/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import PromiseME


class ResultTests: XCTestCase {

    enum TestError: ErrorType {
        case SomeError
        case AnotherError
    }
    
    func testSuccessfullResult() {
        let payload = "this is a test"
        let result = Result.Success(payload)
        
        XCTAssertNotNil(result.value)
        XCTAssert(result.error == nil)
        
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, payload)
        default:
            XCTFail("result was not .Success")
        }
        
        TAssertNoThrow(try result.valueOrThrow())
    }
    
    func testFailedResult() {
        let result = Result<String>.Failure(TestError.SomeError)
        
        XCTAssertNil(result.value)
        if let error = result.error as? TestError where error == .SomeError {
        } else {
            XCTFail("error mismatch")
        }
        
        switch result {
        case .Failure(let error as TestError) :
            XCTAssertEqual(error, TestError.SomeError)
        default:
            XCTFail("result was not .Success")
        }
        
        TAssertThrowSpecific(try result.valueOrThrow(), expected: TestError.SomeError)
    }
    
    func testInitWithThrowingFunction() {
        
        func somethingThatThrows() throws -> Int {
            throw TestError.AnotherError
        }
        
        let result = Result(try somethingThatThrows())
        
        XCTAssertNil(result.value)
        if let error = result.error as? TestError where error == .AnotherError {
        } else {
            XCTFail("error mismatch")
        }
        
        switch result {
        case .Failure(let error as TestError) :
            XCTAssertEqual(error, TestError.AnotherError)
        default:
            XCTFail("result was not .Success")
        }
        
        TAssertThrowSpecific(try result.valueOrThrow(), expected: TestError.AnotherError)
    }
    
    func testInitWithNonThrowingFunction() {
        
        func somethingThatThrows() throws -> Int {
            return 12345
        }
        
        let result = Result(try somethingThatThrows())
        
        XCTAssertNotNil(result.value)
        XCTAssert(result.error == nil)
        
        switch result {
        case .Success(let value):
            XCTAssertEqual(value, 12345)
        default:
            XCTFail("result was not .Success")
        }
        
        TAssertNoThrow(try result.valueOrThrow())
    }
    
    func testNullCoalescing() {
        let resultA = Result.Success("testA")
        let resultB = Result.Success("testB")
        let resultC = Result<String>.Failure(TestError.SomeError)
        let resultD = Result<String>.Failure(TestError.AnotherError)
        
        let ab = resultA ?? resultB
        XCTAssertEqual(ab.value!, "testA")
        
        let bc = resultB ?? resultC
        XCTAssertEqual(bc.value!, "testB")
        
        let cb = resultC ?? resultB
        XCTAssertEqual(cb.value!, "testB")
        
        let cd = resultC ?? resultD
        TAssertErrorType(cd.error!, TestError.AnotherError)
        
        let dcba = resultD ?? resultC ?? resultB ?? resultA
        XCTAssertEqual(dcba.value!, "testB")
    }
    
    func testNullCoalescingWithValues() {
        let resultA = Result.Success("testA")
        let resultB = Result<String>.Failure(TestError.SomeError)
        let resultC = Result<String>.Failure(TestError.AnotherError)
        
        let a = resultA ?? "testX"
        XCTAssertEqual(a, "testA")
        
        let b = resultB ?? "testX"
        XCTAssertEqual(b, "testX")
        
        let e = resultB ?? resultC ?? "final"
        XCTAssertEqual(e, "final")
    }
}

