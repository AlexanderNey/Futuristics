//
//  FunctionCompositionTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
import Futuristics


class FunctionCopositionTests : XCTestCase {

    enum ConvertError: Error {
        case failedToConvertStringToNumber(String)
    }
    
    func stringToNumber(_ str: String) throws -> Int {
        if let number = Int(str) {
            return number
        } else {
            throw ConvertError.failedToConvertStringToNumber(str)
        }
    }
    
    func doubleNumber(_ number: Int) throws -> Int {
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
        
        let throwExpectation = expectation(description: "throw expectation")
        
        do {
            _ = try composition("abc")
            XCTFail("function call expected to throw")
        } catch ConvertError.failedToConvertStringToNumber(let str) {
            if str == "abc" {
                throwExpectation.fulfill()
            }
        } catch {
            XCTFail("generic error not expected")
        }
        
        waitForExpectationsWithDefaultTimeout()
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
        let throwExpectation = expectation(description: "throw expectation")
        
        do {
            _ = try ( "abc" |> stringToNumber |> doubleNumber )
            XCTFail("function call expected to throw")
        } catch ConvertError.failedToConvertStringToNumber(let str) {
            if str == "abc" {
                throwExpectation.fulfill()
            }
        } catch {
            XCTFail("generic error not expected")
        }
        
        waitForExpectationsWithDefaultTimeout()
    }
}
