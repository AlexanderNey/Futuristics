//
//  XCTest+Extension.swift
//  Futuristics
//
//  Created by Ney, Alexander (Agoda) on 4/23/17.
//  Copyright © 2017 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest

extension XCTestCase {

    func waitForExpectationsWithDefaultTimeout(handler: XCWaitCompletionHandler? = nil) {
        waitForExpectations(timeout: 10, handler: handler)
    }

}
