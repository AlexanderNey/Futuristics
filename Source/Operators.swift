//
//  Operators.swift
//  Futuristics
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation

precedencegroup FunctionCompositionPrecedence {
    associativity: left
}

/**
*  Function composition operator for functions
*  used >>> instead of >> to avoid ambiguity
*/
infix operator >>> : FunctionCompositionPrecedence

/**
*  Pipe forward operator to compose & execute functions
*/
infix operator |> : FunctionCompositionPrecedence
