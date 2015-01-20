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



-(NSArray *)fetchObjectsForIndexName:(NSString *)indexName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    return [self fetchObjectsForIndexName:indexName matchingPredicate:predicate sortDescriptors:sortDescriptors fromStores:nil];
}



-(NSArray *)fetchObjectsForIndexName:(NSString *)indexName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fromStores:(NSArray *)storesNames
{
    //Figure out which stores to search
    NSArray *stores = (storesNames == nil || storesNames.count == 0) ? self.storesByName.allValues : ({
        NSMutableArray *stores = [NSMutableArray new];
        for (NSString *storeName in storesNames) {
            BCOObjectStore *store = self.storesByName[storeName];
            if (store != nil) [stores addObject:store];
        }
        stores;
    });

    //Grab all potential matches from the stores
    NSMutableSet *objects = [NSMutableSet new];
    for (BCOObjectStore *store in stores) {
        NSSet *subObjects = [store objectsForIndexName:indexName];
        if (subObjects == nil) continue;
        [objects unionSet:subObjects];
    }

    if (predicate != nil) {
        [objects filterUsingPredicate:predicate];
    }

    return (sortDescriptors.count > 0) ? [objects sortedArrayUsingDescriptors:sortDescriptors] : [objects allObjects];
}

@end
