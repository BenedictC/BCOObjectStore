//
//  BCOIndexDescription.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOIndexDescription.h"



@implementation BCOIndexDescription

-(instancetype)initWithIndexValueGenerator:(BCOIndexValueGenerator)generator valueComparator:(NSComparator)comparator
{
    NSParameterAssert(generator);
    NSParameterAssert(comparator);

    self = [super init];
    if (self == nil) return nil;

    _indexValueGenerator = generator;
    _valueComparator = comparator;

    return self;
}

@end
