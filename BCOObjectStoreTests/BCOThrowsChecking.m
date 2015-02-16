//
//  BCOThrowsChecking.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 06/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOThrowsChecking.h"



BOOL BCODoesThrow(void(^block)(void)) {
    @try {
        block();
    }
    @catch (NSException *exception) {
        return YES;
    }

    return NO;
}

