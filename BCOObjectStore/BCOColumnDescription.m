//
//  BCOColumnDescription.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOColumnDescription.h"



@implementation BCOColumnDescription

-(instancetype)initWithColumnValueGenerator:(BCOColumnValueGenerator)generator valueComparator:(NSComparator)comparator
{
    NSParameterAssert(generator);
    NSParameterAssert(comparator);

    self = [super init];
    if (self == nil) return nil;

    _columnValueGenerator = generator;
    _valueComparator = comparator;

    return self;
}

@end
