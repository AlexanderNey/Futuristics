//
//  FutureCompositionTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import Futuristics


class FutureCompositionTests : XCTestCase {
    
    enum TestError: Error {
        case failedToConvertNumberToString(Int)
        case anotherError
    }

    let someBackgroungQueue = DispatchQueue(label: "test queue")
    
    func generateTestInt(_ number: Int) -> Future<Int> {
        let promise = Promise<Int>()
        someBackgroungQueue.async {
            promise.fulfill(number)
        }
        return promise.future
    }
    
    func numberToString(_ number: Int) -> Future<String> {
        let promise = Promise<String>()
        someBackgroungQueue.async {
            let str = String(number)
            promise.fulfill(str)
        }
        return promise.future
    }
    
    func stringToNumber(_ str: String) -> Future<Int> {
        let promise = Promise<Int>()
        someBackgroungQueue.async {
            promise.fulfill(Int(str)!)
        }
        return promise.future
    }
    
    func numberToStringThrows(_ number: Int) -> Future<String> {
        let promise = Promise<String>()
        someBackgroungQueue.async {
            promise.reject(TestError.failedToConvertNumberToString(number))
        }
        return promise.future
    }
    
    func doubleNumber(_ number: Int) -> Future<Int> {
        let promise = Promise<Int>()
        promise.fulfill(number * 2)
        return promise.future
    }
    
    
    func testSuccessfulPromiseFunctionComposition() {
        let composition = generateTestInt >>> doubleNumber >>> numberToString >>> stringToNumber >>> doubleNumber >>> numberToString
        
        let succeedExpectation = expectation(description: "should succeed")
        composition(444).onSuccess { str in
            if str == "1776" {
                succeedExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 4, handler: nil)
  }
    
    func testFailurePromiseFunctionComposition() {
        let composition = generateTestInt >>> doubleNumber >>> numberToStringThrows >>> stringToNumber
        
        let failureExpectation = expectation(description: "should fail")
        composition(444).onFailure { error in
            if let testError = error as? TestError {
                switch testError {
                case .failedToConvertNumberToString(let number) where number == 888:
                    failureExpectation.fulfill()
                default:
                    XCTFail("failedToConvertNumberToString(888) error expected but got \(error)")
                }
            }
        }

        waitForExpectations(timeout: 2, handler: nil)
    }


    func testPromiseFunctionCompositionInvocation() {
        let succeedExpectation = expectation(description: "should succeed")
        let result = 100 |> doubleNumber |> numberToString |> stringToNumber |> doubleNumber
        result.onSuccess { number in
            if number == 400 {
                succeedExpectation.fulfill()
            }
        }
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    func testPromiseFunctionCompositionInvocationThrowing() {
        let failureExpectation = expectation(description: "should fail")
        let result = 100 |> doubleNumber |> numberToStringThrows |> stringToNumber
        result.onFailure { error in
            failureExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 4, handler: nil)
    }
    
    
    func testFunctionCompositionPerformance() {
        
        measure() {
            var counter = 0
            for _ in 0...1000 {
                func doubleNumber(_ number: Int) -> Future<Int> {
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
