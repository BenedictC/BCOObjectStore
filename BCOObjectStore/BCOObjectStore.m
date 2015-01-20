//
//  BCOObjectStore.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStore.h"
#import "BCOIndexDescription.h"
#import "BCOIndex.h"



@interface BCOObjectStore ()

@property(readonly) NSDictionary *indexesByIndexName;

@end



@implementation BCOObjectStore

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    self = [super init];
    if (self == nil) return nil;

    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build an index for each description
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        //Create and store the index
        BCOIndex *storeIndex = [[BCOIndex alloc] initWithObjects:objects indexDescription:indexDescription];
        indexesByIndexName[indexName] = storeIndex;
    }];
    _indexesByIndexName = indexesByIndexName;

    return self;
}



-(NSSet *)objectsForKeys:(NSArray *)keys inIndexNamed:(NSString *)indexName
{
    BCOIndex *index = self.indexesByIndexName[indexName];
    if (index == nil) return [NSSet set];

    NSMutableSet *allObjects = [NSMutableSet new];
    for (id key in keys) {
        NSSet *objects = [index objectsForKey:key];
        [allObjects unionSet:objects];
    }

    return allObjects;
}

@end
