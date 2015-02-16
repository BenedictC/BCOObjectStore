//
//  BCOObjectStorageEnumerator.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStorageEnumerator.h"
#import "BCOObjectStorageContainer+Protected.h"



@implementation BCOObjectStorageEnumerator

-(instancetype)initWithStorageContainer:(BCOObjectStorageContainer *)storageContainer records:(id<NSFastEnumeration>)records
{
    NSParameterAssert(storageContainer);

    self = [super init];
    if (self == nil) return nil;

    _storageContainer = storageContainer;
    _records = records;

    return self;
}



-(void)enumerateStorageRecordsUsingBlock:(void(^)(BCOStorageRecord *record, BOOL *stop))block
{
    if (self.records != nil) {
        BOOL stop = NO;
        for (BCOStorageRecord *record in self.records) {
            block(record, &stop);
            if (stop) return;
        }
        return;
    }

    NSMutableSet *visitedRecords = [NSMutableSet new];
    BCOObjectStorageContainer *container = self.storageContainer;

    while (container != nil) {

        [container.objectsByStorageRecords enumerateKeysAndObjectsUsingBlock:^(BCOStorageRecord *record, id obj, BOOL *stop) {
            BOOL isVisited = [visitedRecords containsObject:record];
            if (isVisited) return;

            [visitedRecords addObject:record];

            if (obj != [NSNull null]) block(record, stop);
        }];

        container = container.previousContainer;
    }
}



-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block
{
    BCOObjectStorageContainer *container = self.storageContainer;

    [self enumerateStorageRecordsUsingBlock:^(BCOStorageRecord *record, BOOL *stop) {
        id object = [container objectForStorageRecord:record];
        block(record, object, stop);
    }];
}

@end
