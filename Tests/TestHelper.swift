//
//  TAssertHelper.swift
//  Futuristics
//
//  Created by Alexander Ney on 04/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest


func TAssertNoThrow(_ f: (Void) throws -> Any) {
    do {
        _ = try f()
    } catch {
        XCTFail("was not expected to throw \(error)")
    }
}


func TAssertThrow(_ f: (Void) throws -> Any) {
    do {
        _ = try f()
        XCTFail("was expected to throw")
    } catch {
        
    }
}

func TAssertThrowSpecific<T: Equatable>(_ f: (Void) throws -> Any, expected: T) {
    do {
        _ = try f()
        XCTFail("was expected to throw")
    } catch {
        if let e = error as? T, e == expected {

        } else {
            XCTFail("was expected to throw \(expected) but throwed \(error) instead")
        }
    }
}

func TAssertErrorType<T: Equatable>(_ error: Error, _ expected: T) {
    if let e = error as? T, e == expected {
    } else {
        XCTFail("expected \(expected) but got \(error) instead")
    }
}
