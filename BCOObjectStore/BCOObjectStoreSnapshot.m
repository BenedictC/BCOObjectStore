//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndex.h"



@interface BCOObjectStoreSnapshot ()
@property(nonatomic, readonly) BCOIndex *storeIndex;
@end



@implementation BCOObjectStoreSnapshot

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    self = [super init];
    if (self == nil) return nil;

    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build an index
    //TODO: Make this more efficent
    _storeIndex = [[BCOIndex alloc] initWithObjects:objects indexDescriptions:indexDescriptions];

    return self;
}



-(NSSet *)objectsForKeys:(NSArray *)keys inIndexNamed:(NSString *)indexName
{
    NSMutableSet *allObjects = [NSMutableSet new];
    for (id key in keys) {
        NSSet *objects = [self.storeIndex objectsForKey:key inIndexNamed:indexName];
        if (objects != nil) [allObjects unionSet:objects];
    }
    return allObjects;
}



-(NSArray *)fetchObjectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    NSSet *matchingObjects = (predicate == nil) ? self.objects : [self.objects filteredSetUsingPredicate:predicate];

    return (sortDescriptors.count > 0) ? [matchingObjects sortedArrayUsingDescriptors:sortDescriptors] : [matchingObjects allObjects];
}



-(NSArray *)fetchObjectsFromIndexNamed:(NSString *)indexName withKeyInArray:(NSArray *)keys sortDescriptors:(NSArray *)sortDescriptors
{
    NSSet *matchingObjects = [self objectsForKeys:keys inIndexNamed:indexName];

    return (sortDescriptors.count > 0) ? [matchingObjects sortedArrayUsingDescriptors:sortDescriptors] : [matchingObjects allObjects];
}

@end
