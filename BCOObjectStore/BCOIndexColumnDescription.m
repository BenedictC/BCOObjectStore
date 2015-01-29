//
//  BCOIndexColumnDescription.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOIndexColumnDescription.h"



@implementation BCOIndexColumnDescription

-(instancetype)initWithIndexKeyGenerator:(BCOColumnKeyGenerator)indexer keyComparator:(NSComparator)comparator
{
    NSParameterAssert(indexer);
    NSParameterAssert(comparator);

    self = [super init];
    if (self == nil) return nil;

    _indexKeyGenerator = indexer;
    _keyComparator = comparator;

    return self;
}

@end
