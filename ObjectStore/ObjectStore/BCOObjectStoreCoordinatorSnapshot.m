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



-(NSDictionary *)fetchAllObjectsOfClass:(Class)indexedClass
{
    return [self fetchAllObjectsOfClass:indexedClass fromStores:nil];
}



-(id)fetchObjectWithPrimaryID:(id)uniqueID class:(id)indexedClass
{
    return [self fetchObjectWithPrimaryID:indexedClass class:uniqueID fromStores:nil];
}



-(NSDictionary *)fetchAllObjectsOfClass:(Class)indexedClass fromStores:(NSArray *)storesNames
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

    //Search for matches
    NSMutableDictionary *objectsByUniqueID = [NSMutableDictionary new];
    for (BCOObjectStore *store in stores) {
        NSDictionary *subObjects = [store fetchObjectsOfClass:indexedClass];
        if (subObjects == nil) continue;
        [objectsByUniqueID addEntriesFromDictionary:subObjects];
    }

    return objectsByUniqueID;
}



-(id)fetchObjectWithPrimaryID:(Class)indexedClass class:(id)uniqueID fromStores:(NSArray *)storesNames
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

    //Search for matches
    //TODO: Should we check other stores for duplicates/mismatches?
    for (BCOObjectStore *store in stores) {
        id object = [store fetchObjectOfClass:indexedClass uniqueID:uniqueID];
        if (object != nil) return object;
    }
    
    return nil;
}

@end
