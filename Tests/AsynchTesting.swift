//
//  AsynchTesting.swift
//  Futuristics
//
//  Created by Alexander Ney on 25/01/2016.
//  Copyright © 2016 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest


class AsynchTestExpectation {
    fileprivate let sem: DispatchSemaphore
    let description: String
    
    init (_ description: String) {
        self.description = description
        self.sem = DispatchSemaphore(value: 0)
    }
    
    func fulfill() {
        self.sem.signal()
    }

    func waitForExpectationsWithTimeout(_ timeout: TimeInterval = 2.0,
                                        handler: ((Void) -> Void)? = nil) {
        
        let end = Date(timeIntervalSinceNow: timeout)
        let interval: TimeInterval  = 0.01
        var didFulfill = false
        while (end.compare(Date()) == .orderedDescending) {
            let intervalTimeout: DispatchTime = DispatchTime.now() + Double(Int64(interval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC);
            let waitResult = self.sem.wait(timeout: intervalTimeout)
            if case .success = waitResult {
                didFulfill = true
                break
            }
            
            if !RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: interval)) {
                Thread.sleep(forTimeInterval: interval)
            }
        }
        
        if !didFulfill {
             XCTFail("\(self.description) timed out after \(timeout) second(s)")
        }
    }

}
