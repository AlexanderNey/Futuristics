//
//  FunctionCompositionTests.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


import Foundation
import XCTest
import PromiseME


class FunctionCopositionTests : XCTestCase {

    enum ConvertError: ErrorType {
        case FailedToConvertStringToNumber(String)
    }
    
    func stringToNumber(str: String) throws -> Int {
        if let number = Int(str) {
            return number
        } else {
            throw ConvertError.FailedToConvertStringToNumber(str)
        }
    }
    
    func doubleNumber(number: Int) throws -> Int {
        return number * 2
    }
    
    func testBasicFunctionComposition() {
        
        let composition = stringToNumber >>> doubleNumber
        
        do {
            let result = try composition("100")
            XCTAssertEqual(result, 200)
        } catch {
            XCTFail("function call not expected to throw")
        }
        
    }
    
    func testBasicFunctionCompositionThrowing() {
        let composition = stringToNumber >>> doubleNumber
        
        let throwExpectation = self.expectationWithDescription("throw expectation")
        
        do {
            try composition("abc")
            XCTFail("function call expected to throw")
        } catch ConvertError.FailedToConvertStringToNumber(let str) {
            if str == "abc" {
                throwExpectation.fulfill()
            }
        } catch {
            XCTFail("generic error not expected")
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    func testBasicFunctionCompositionInvocation() {
        do {
            let result = try "100" |> stringToNumber |> doubleNumber
            XCTAssertEqual(result, 200)
        } catch {
            XCTFail("function call not expected to throw")
        }
    }
    
    func testBasicFunctionCompositionInvocationThrowing() {
        let throwExpectation = self.expectationWithDescription("throw expectation")
        
        do {
            try "abc" |> stringToNumber |> doubleNumber
            XCTFail("function call expected to throw")
        } catch ConvertError.FailedToConvertStringToNumber(let str) {
            if str == "abc" {
                throwExpectation.fulfill()
            }
        } catch {
            XCTFail("generic error not expected")
        }
        
        self.waitForExpectationsWithTimeout(1, handler: nil)
    }
}