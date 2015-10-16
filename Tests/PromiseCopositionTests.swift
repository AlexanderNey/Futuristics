//
//  PromiseCopositionTests.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import PromiseME


class PromiseCopositionTests : XCTestCase {
    
    enum TestError: ErrorType {
        case FailedToConvertNumberToString(Int)
        case AnotherError
    }
    
    
    func generateTestInt(number: Int) -> Future<Int> {
        let promise = Promise<Int>()
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            promise.fulfill(number)
        }
        return promise.future
    }
    
    func numberToString(number: Int) -> Future<String> {
        let promise = Promise<String>()
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            let str = String(number)
            promise.fulfill(str)
        }
        return promise.future
    }
    
    func stringToNumber(str: String) -> Future<Int> {
        let promise = Promise<Int>()
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            promise.fulfill(Int(str)!)
        }
        return promise.future
    }
    
    func numberToStringThrows(number: Int) -> Future<String> {
        let promise = Promise<String>()
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)) {
            promise.reject(TestError.FailedToConvertNumberToString(number))
        }
        return promise.future
    }
    
    func doubleNumber(number: Int) -> Future<Int> {
        let promise = Promise<Int>()
        promise.fulfill(number * 2)
        return promise.future
    }
    
    
    func testSuccessfulPromiseFunctionComposition() {
        let composition = generateTestInt >>> doubleNumber >>> numberToString >>> stringToNumber >>> doubleNumber >>> numberToString
        
        let succeedExpectation = self.expectationWithDescription("should succeed")
        composition(444).onSuccess { str in
            if str == "1776" {
                succeedExpectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testFailurePromiseFunctionComposition() {
        let composition = generateTestInt >>> doubleNumber >>> numberToStringThrows >>> stringToNumber
        
        let failureExpectation = self.expectationWithDescription("should fail")
        composition(444).onFailure { error in
            if let testError = error as? TestError {
                switch testError {
                case .FailedToConvertNumberToString(let number) where number == 888:
                    failureExpectation.fulfill()
                default:
                    XCTFail("FailedToConvertNumberToString error expected")
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testPromiseFunctionCompositionInvocation() {
        let succeedExpectation = self.expectationWithDescription("should succeed")
        let result = 100 |> doubleNumber |> numberToString |> stringToNumber |> doubleNumber
        result.onSuccess { number in
            if number == 400 {
                succeedExpectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testPromiseFunctionCompositionInvocationThrowing() {
        let failureExpectation = self.expectationWithDescription("should fail")
        let result = 100 |> doubleNumber |> numberToStringThrows |> stringToNumber
        result.onFailure { error in
            failureExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    
    func testFunctionCompositionPerformance() {
        
        measureBlock() {
            var counter = 0
            for _ in 0...5000 {
                func doubleNumber(number: Int) -> Future<Int> {
                    let promise = Promise<Int>()
                    promise.fulfill(number)
                    return promise.future
                }
                
                let composition = doubleNumber >>> doubleNumber >>> doubleNumber >>> doubleNumber >>> doubleNumber >>> doubleNumber >>> doubleNumber >>> doubleNumber >>> doubleNumber  >>> doubleNumber
                
                composition(1).onSuccess { str in
                    counter += 1
                }.onFailure { error in
                    counter += 1
                }.finally {
                   counter += 1
                }
            }
        }
        
    }
}