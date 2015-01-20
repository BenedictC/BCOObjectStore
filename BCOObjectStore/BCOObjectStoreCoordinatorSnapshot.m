//
//  BCOObjectStoreCoordinatorSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreCoordinatorSnapshot.h"
#import "BCOObjectStore.h"



@implementation BCOObjectStoreCoordinatorSnapshot

-(instancetype)initWithStoresByName:(NSDictionary *)storesByName
{
    NSParameterAssert(storesByName);

    self = [super init];
    if (self == nil) return nil;

    _storesByName = [storesByName copy];

    return self;
}



-(NSArray *)fetchObjectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    //Figure out which stores to search
    NSArray *stores = self.storesByName.allValues;

    //Grab matching object from the stores
    NSMutableSet *objects = [NSMutableSet new];
    for (BCOObjectStore *store in stores) {
        NSSet *matchingObjects = (predicate == nil) ? store.objects : [store.objects filteredSetUsingPredicate:predicate];
        [objects unionSet:matchingObjects];
    }

    return (sortDescriptors.count > 0) ? [objects sortedArrayUsingDescriptors:sortDescriptors] : [objects allObjects];
}



-(NSArray *)fetchObjectsFromIndexNamed:(NSString *)indexName withKeyInArray:(NSArray *)keys sortDescriptors:(NSArray *)sortDescriptors
{
    //Figure out which stores to search
    NSArray *stores = self.storesByName.allValues;

    //Grab all potential matches from the stores
    NSMutableSet *objects = [NSMutableSet new];
    for (BCOObjectStore *store in stores) {
        NSSet *subObjects = [store objectsForKeys:keys inIndexNamed:indexName];
        
        if (subObjects == nil) continue;

        [objects unionSet:subObjects];
    }

    return (sortDescriptors.count > 0) ? [objects sortedArrayUsingDescriptors:sortDescriptors] : [objects allObjects];
}

@end
