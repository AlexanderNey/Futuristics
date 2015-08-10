//
//  FunctionComposition.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


public func >>> <A,B,C>(left: A throws -> B, right: B throws -> C) -> (A throws -> C) {
    return { (parameter: A) throws -> C in
        let finalResult = try right(left(parameter))
        return finalResult
    }
}


public func |> <A,B>(left: A, right: A throws -> B) throws -> B {
    return try right(left)
}