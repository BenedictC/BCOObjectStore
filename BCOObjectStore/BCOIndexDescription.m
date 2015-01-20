//
//  BCOIndexDescription.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOIndexDescription.h"



@implementation BCOIndexDescription

-(instancetype)initWithIndexer:(BCOIndexer)indexer
{
    NSParameterAssert(indexer);

    self = [super init];
    if (self == nil) return nil;

    _indexer = indexer;

    return self;
}

@end
