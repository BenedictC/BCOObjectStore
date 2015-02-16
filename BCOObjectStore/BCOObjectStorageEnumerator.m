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

-(instancetype)initWithStorageContainer:(BCOObjectStorageContainer *)storageContainer references:(id<NSFastEnumeration>)references
{
    NSParameterAssert(storageContainer);

    self = [super init];
    if (self == nil) return nil;

    _storageContainer = storageContainer;
    _references = references;

    return self;
}



-(void)enumerateObjectReferencesUsingBlock:(void(^)(BCOObjectReference *reference, BOOL *stop))block
{
    if (self.references != nil) {
        BOOL stop = NO;
        for (BCOObjectReference *reference in self.references) {
            block(reference, &stop);
            if (stop) return;
        }
        return;
    }

    NSMutableSet *visitedReferences = [NSMutableSet new];
    BCOObjectStorageContainer *container = self.storageContainer;

    while (container != nil) {

        [container.objectsByObjectReferences enumerateKeysAndObjectsUsingBlock:^(BCOObjectReference *reference, id obj, BOOL *stop) {
            BOOL isVisited = [visitedReferences containsObject:reference];
            if (isVisited) return;

            [visitedReferences addObject:reference];

            if (obj != [NSNull null]) block(reference, stop);
        }];

        container = container.previousContainer;
    }
}



-(void)enumerateObjectReferencesAndObjectsUsingBlock:(void(^)(BCOObjectReference *reference, id object, BOOL *stop))block
{
    BCOObjectStorageContainer *container = self.storageContainer;

    [self enumerateObjectReferencesUsingBlock:^(BCOObjectReference *reference, BOOL *stop) {
        id object = [container objectForObjectReference:reference];
        block(reference, object, stop);
    }];
}

@end
