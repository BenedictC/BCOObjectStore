//
//  BCOIndexDescription.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOIndexDescription.h"



@implementation NSObject (BCOIndexDescription)

-(NSString *)BCOIndexDescription_defaultUniqueID
{
    return [NSString stringWithFormat:@"%p", self];
}

@end



@implementation BCOIndexDescription

-(instancetype)initWithIndexedClass:(Class)indexedClass valueKeyPath:(NSString *)valueKeyPath
{
    NSParameterAssert(indexedClass);

    self = [super init];
    if (self == nil) return nil;

    _indexedClass = indexedClass;
    _valueKeyPath = [valueKeyPath copy] ?: NSStringFromSelector(@selector(BCOIndexDescription_defaultUniqueID));

    return self;
}

@end
