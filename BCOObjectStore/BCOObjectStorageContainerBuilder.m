//
//  BCOObjectStorageContainerBuilder.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStorageContainerBuilder.h"
#import "BCOObjectStorageContainer+Protected.h"
#import "BCOObjectReference.h"



@implementation BCOObjectStorageContainerBuilder
{
    BCOObjectStorageContainer *_previousContainer;
    NSMutableDictionary *_objectsByObjectReferences;
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
    _objectsByObjectReferences = [NSMutableDictionary new];

    return self;
}



#pragma mark -
-(BCOObjectReference *)addObject:(id)object
{
    BCOObjectReference *reference = [BCOObjectReference objectReferenceForObject:object];
    _objectsByObjectReferences[reference] = object;

    return reference;
}



-(void)removeObjectForObjectReference:(BCOObjectReference *)objectReference
{
    _objectsByObjectReferences[objectReference] = [NSNull null];
}



-(BCOObjectStorageContainer *)finalize
{
    return [[BCOObjectStorageContainer alloc] initWithObjectsByObjectReferences:_objectsByObjectReferences previousContainer:_previousContainer persistentStorageManager:_previousContainer.persistentStorageManager];
}

@end
