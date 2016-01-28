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
    private let sem: dispatch_semaphore_t
    let description: String
    private var rejected: Bool = false
    
    init (_ description: String) {
        self.description = description
        self.sem = dispatch_semaphore_create(0)
    }
    
    func fulfill() {
        dispatch_semaphore_signal(self.sem)
    }
    
    func reject() {
        rejected = true
    }

    func waitForExpectationsWithTimeout(timeout: NSTimeInterval = 2.0, mustFulfill: Bool = true, handler: (Void -> Void)? = nil) {
        
        let end = NSDate(timeIntervalSinceNow: timeout)
        let interval: NSTimeInterval  = 0.01
        var didFulfill = false
        while (end.compare(NSDate()) == .OrderedDescending) {
            let intervalTimeout: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * Double(NSEC_PER_SEC)));
            let waitResult = dispatch_semaphore_wait(self.sem, intervalTimeout)
            didFulfill = waitResult == 0
            if didFulfill {
                break
            }
            
            if !NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate(timeIntervalSinceNow: interval)) {
                NSThread.sleepForTimeInterval(interval)
            }
        }
        
        if didFulfill != mustFulfill {
            XCTFail("\(self.description) was expected to be \(mustFulfill ? "" : "not" ) fulfilled")
        }
    }

}