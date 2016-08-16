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
    
    enum TestError: Error {
        case timedOut
    }
    
    private let sem: DispatchSemaphore
    let description: String
    
    init (_ description: String) {
        self.description = description
        self.sem = DispatchSemaphore(value: 0)
    }
    
    func fulfill() {
        self.sem.signal()
    }

    func waitForExpectationsWithTimeout(_ timeout: TimeInterval = 2.0, handler: ((Void) -> Void)? = nil) {
        
        let endDate = Date(timeIntervalSinceNow: timeout)
        let interval: TimeInterval  = 0.01
        do {
            waitLoop: while (true) {
                guard Date() < endDate else {
                    throw TestError.timedOut
                }
                
                let intervalTimeout: DispatchTime = .now() + interval
                let waitResult = self.sem.wait(timeout: intervalTimeout)
                
                switch waitResult {
                case .success:
                    break waitLoop
                case .timedOut:
                    if !RunLoop.current.run(mode: RunLoopMode.defaultRunLoopMode, before: Date(timeIntervalSinceNow: interval)) {
                        Thread.sleep(forTimeInterval: interval)
                    }
                }
            }
        } catch TestError.timedOut {
            XCTFail("\(self.description) timed out after \(timeout) second(s)")
        } catch {
            XCTFail("\(self.description) failed with unhandled error \(error)")
        }
        
    }

}
