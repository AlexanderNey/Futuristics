//
//  Operators.swift
//  PromiseME
//
//  Created by Alexander Ney on 05/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation


/**
*  Function composition operator for functions
*  used >>> instead of >> to avoid ambiguity
*/
infix operator >>> { precedence 50 associativity left }

/**
*  Pipe forward operator to compose & execute functions
*/
infix operator |> { precedence 50 associativity left }