//
//  BCOObjectStorageContainerBuilder.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStorageContainerBuilder.h"
#import "BCOObjectStorageContainer+Protected.h"
#import "BCOStorageRecord.h"



@implementation BCOObjectStorageContainerBuilder
{
    BCOObjectStorageContainer *_previousContainer;
    NSMutableDictionary *_objectsByStorageRecords;
}



#pragma mark - Instance life cycle
+(instancetype)builderWithPreviousStorageContainer:(BCOObjectStorageContainer *)previousContainer
{
    return [[self alloc] initWithPreviousStorageContainer:previousContainer];
}



-(instancetype)init
{
    return [self initWithPreviousStorageContainer:nil];
}



-(instancetype)initWithPreviousStorageContainer:(BCOObjectStorageContainer *)previousContainer
{
    self = [super init];
    if (self == nil) return nil;

    _previousContainer = previousContainer;
    _objectsByStorageRecords = [NSMutableDictionary new];

    return self;
}



#pragma mark -
-(BCOStorageRecord *)addObject:(id)object
{
    BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];
    _objectsByStorageRecords[record] = object;

    return record;
}



-(void)removeObjectForStorageRecord:(BCOStorageRecord *)storageRecord
{
    _objectsByStorageRecords[storageRecord] = [NSNull null];
}



-(BCOObjectStorageContainer *)finalize
{
    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:_objectsByStorageRecords previousContainer:_previousContainer];
}

@end
