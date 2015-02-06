//
//  BCOThrowsChecking.swift
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

import Foundation



func BCOThrows(expression: @autoclosure () -> Void) -> Bool
{
    return BCODoesThrow(expression)
}



func BCONoThrow(expression: @autoclosure () -> Void) -> Bool
{
    return !BCODoesThrow(expression)
}


