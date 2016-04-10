//
//  FunctionComposition.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation

/**
 Composition operator which creates a new function out of the two given ones
 
 - parameter left:  a function that have a result that can be set as an argument to the right function
 - parameter right: a function that can receive an argument that matches the resulttype  of the left function
 
 - throws: throws an error emitted due to the execution of either left or right function
 
 - returns: a new function that with the argument signature of the left function and the result signature of the right function
 */
public func >>> <A,B,C>(left: A throws -> B, right: B throws -> C) -> (A throws -> C) {
    return { (parameter: A) throws -> C in
        let finalResult = try right(left(parameter))
        return finalResult
    }
}


/**
 The pipe forward composition operator is very similar to the >>> operator with the only difference that it does not create
 a new function as a result but invokes the given functions straight away
 
 - parameter left:  a function that have a result that can be set as an argument to the right function
 - parameter right: a function that can receive an argument that matches the result of the left function
 
 - throws: throws an error emitted due to the execution of either left or right function
 
 - returns: the result of the `right` function
 */
public func |> <A,B>(left: A, right: A throws -> B) throws -> B {
    return try right(left)
}