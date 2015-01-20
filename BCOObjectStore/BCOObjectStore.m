//
//  BCOObjectStore.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStore.h"
#import "BCOIndexDescription.h"



#pragma mark - BCOObjectStoreIndex
@interface BCOObjectStoreIndex : NSObject
@property(readonly) BCOIndexDescription *indexDescription;
@property(readonly) NSSet *indexedObjects;
@property(readonly) NSMutableDictionary *objectSetsByKey;
@end



@implementation BCOObjectStoreIndex

-(instancetype)initWithObjects:(NSSet *)objects indexDescription:(BCOIndexDescription *)indexDescription
{
    NSParameterAssert(objects);
    NSParameterAssert(indexDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexDescription = indexDescription;

    NSMutableSet *indexedObjects = [NSMutableSet new];
    NSMutableDictionary *objectSetsByKey = [NSMutableDictionary new];
    BCOIndexer indexer = indexDescription.indexer;
    for (id value in objects) {
        id key = indexer(value);
        if (key != nil) {
#pragma message "TODO: take isUnique into account"
            NSMutableSet *objectSet = objectSetsByKey[key];
            if (objectSet == nil) {
                objectSet = [NSMutableSet new];
                objectSetsByKey[key] = objectSet;
            }
            [objectSet addObject:value];
            [indexedObjects addObject:value];
        }
    }
    _indexedObjects = indexedObjects;
    _objectSetsByKey = objectSetsByKey;

    return self;
}



-(id)objectSetForKey:(id)key
{
    return self.objectSetsByKey[key];
}

@end





#pragma mark - BCOObjectStore
@interface BCOObjectStore ()

@property(readonly) NSDictionary *storeIndexesByIndexName;

@end



@implementation BCOObjectStore

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    self = [super init];
    if (self == nil) return nil;

    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build an index for each description
    NSMutableDictionary *storeIndexesByIndexName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        //Create and store the index
        BCOObjectStoreIndex *storeIndex = [[BCOObjectStoreIndex alloc] initWithObjects:objects indexDescription:indexDescription];
        storeIndexesByIndexName[indexName] = storeIndex;
    }];
    _storeIndexesByIndexName = storeIndexesByIndexName;

    return self;
}



-(NSSet *)objectsForIndexName:(NSString *)indexName
{
    BCOObjectStoreIndex *index = self.storeIndexesByIndexName[indexName];
    return [index indexedObjects];
}



-(NSSet *)objectsForIndexName:(NSString *)indexName key:(id)key
{
   BCOObjectStoreIndex *index = self.storeIndexesByIndexName[indexName];
    return [index objectSetForKey:key];
}

@end
