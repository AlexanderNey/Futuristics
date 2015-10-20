//
//  TAssertHelper.swift
//  Futuristics
//
//  Created by Alexander Ney on 04/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest


func TAssertNoThrow(@autoclosure f: (Void throws -> Any)) {
    do {
        try f()
    } catch {
        XCTFail("was not expected to throw \(error)")
    }
}


func TAssertThrow(@autoclosure f: (Void throws -> Any)) {
    do {
        try f()
        XCTFail("was expected to throw")
    } catch {
        
    }
}

func TAssertThrowSpecific<T: Equatable>(@autoclosure f: (Void throws -> Any), expected: T) {
    do {
        try f()
        XCTFail("was expected to throw")
    } catch {
        if let e = error as? T where e == expected {

        } else {
            XCTFail("was expected to throw \(expected) but throwed \(error) instead")
        }
    }
}

func TAssertErrorType<T: Equatable>(error: ErrorType, _ expected: T) {
    if let e = error as? T where e == expected {
    } else {
        XCTFail("expected \(expected) but got \(error) instead")
    }
}