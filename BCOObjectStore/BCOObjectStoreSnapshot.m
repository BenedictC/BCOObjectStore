//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"



@interface BCOIndexReference : NSObject <NSCopying>
@property(nonatomic, readonly) NSString *indexName;
@property(nonatomic, readonly) id key;
@end



@implementation BCOIndexReference;

-(instancetype)initWithIndexName:(NSString *)indexName key:(id)key
{
    self = [super init];
    if (self == nil) return nil;

    _indexName = [indexName copy];
    _key = key;

    return self;
}



-(NSUInteger)hash
{
    return self.class.hash ^ self.indexName.hash ^ [self.key hash];
}



-(BOOL)isEqual:(id)object
{
    if (self == object) return YES;

    if (![[object class] isEqual:BCOIndexReference.class]) return NO;

    return [object hash] == self.hash;
}



-(id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end



@interface BCOObjectStoreSnapshot ()
@property(readonly) NSDictionary *indexesByIndexName;
@property(readonly) NSMapTable *referenceSetsByObject;
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(objects);
    NSParameterAssert(indexDescriptions);

    self = [super init];
    if (self == nil) return nil;

    //Store ivars
    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build index
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    NSMapTable *referenceSetsByObject = [NSMapTable strongToStrongObjectsMapTable];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        //Create and add the index
        NSMutableDictionary *index = [NSMutableDictionary new];
        indexesByIndexName[indexName] = index;

        //Add each object to the index
        BCOIndexer indexer = indexDescription.indexer;
        for (id object in objects) {
            id key = indexer(object);
            if (key == nil) continue;

            //Fetch/create the bucket to store the object in
            NSMutableSet *objectsBucket = index[key];
            if (objectsBucket == nil) {
                objectsBucket = [NSMutableSet new];
                index[key] = objectsBucket;
            }

            //Store the object
            [objectsBucket addObject:object];

            //Create a reference
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            NSMutableSet *referenceSet = [referenceSetsByObject objectForKey:object];
            if (referenceSet == nil) {
                referenceSet = [NSMutableSet new];
                [referenceSetsByObject setObject:referenceSet forKey:object];
            }
            [referenceSet addObject:reference];
        }
    }];
    _indexesByIndexName = indexesByIndexName;
    _referenceSetsByObject = referenceSetsByObject;

    return self;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)allObjects
{
    NSSet *oldObjects = self.objects;
    NSMutableSet *freshObjects = [allObjects mutableCopy];
    [freshObjects minusSet:oldObjects];
    NSMutableSet *expiredObjects = [oldObjects mutableCopy];
    [expiredObjects minusSet:allObjects];

    return [self snapshotByRemovingObjects:expiredObjects addingObjects:freshObjects];
}



-(BCOObjectStoreSnapshot *)snapshotByRemovingObjects:(NSSet *)expiredObjects addingObjects:(NSSet *)freshObjects
{
    NSDictionary *indexDescriptions = self.indexDescriptions;

    NSMutableSet *newObjects = [self.objects mutableCopy];
    //Note that it's not safe to modify the objectsSets!
    NSMutableDictionary *newIndexesByIndexName = ({
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            dict[key] = [obj mutableCopy];
        }];
        dict;
    });
    NSMapTable *newReferenceSetsByObject = [self.referenceSetsByObject copy];

    //Remove expired objects from...
    NSMutableDictionary *objectsSetsToRemoveByIndexReference = [NSMutableDictionary new];
    for (id expiredObject in expiredObjects) {
        //...each index (by looking up each reference)
        NSSet *references = [newReferenceSetsByObject objectForKey:expiredObject];
        for (BCOIndexReference *reference in references) {

            //Get victims
            NSMutableSet *victims = objectsSetsToRemoveByIndexReference[reference];
            if (victims == nil) {
                victims = [NSMutableSet new];
                objectsSetsToRemoveByIndexReference[reference] = victims;
            }
            [victims addObject:expiredObject];
        }
        //...the reference set
        [newReferenceSetsByObject removeObjectForKey:expiredObject];

        //.. all objects
        [newObjects removeObject:expiredObject];
    }

    //TODO: Describe what's happening
    [objectsSetsToRemoveByIndexReference enumerateKeysAndObjectsUsingBlock:^(BCOIndexReference *reference, NSSet *victims, BOOL *stop) {
        NSMutableDictionary *index = newIndexesByIndexName[reference.indexName];
        NSSet *oldObjectsSet = index[reference.key];
        NSMutableSet *newObjectsSet = [oldObjectsSet mutableCopy];
        [newObjectsSet minusSet:victims];
        index[reference.key] = newObjectsSet;
    }];


    //Add freshObjects to all objects
    [newObjects unionSet:freshObjects];
    //Add freshObjects to each index
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {

        NSMutableDictionary *freshIndex = [NSMutableDictionary new];
        BCOIndexer indexer = indexDescription.indexer;
        for (id freshObject in freshObjects) {
            //Generate a key
            id key = indexer(freshObject);
            if (key == nil) continue;

            //Create the new objectsSet
            NSMutableSet *objectsSet = freshIndex[key];
            if (objectsSet == nil) {
                objectsSet = [NSMutableSet new];
                freshIndex[key] = objectsSet;
            }
            [objectsSet addObject:freshObject];

            //Add the object to the referencesSet
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            NSSet *existingReferencesSet = [newReferenceSetsByObject objectForKey:freshObject];
            NSSet *newReferencesSet = (existingReferencesSet == nil) ? [NSSet setWithObject:reference] : [existingReferencesSet setByAddingObject:reference];
            [newReferenceSetsByObject setObject:newReferencesSet forKey:freshObject];
        }

        //Make a copy of the index...
        NSMutableDictionary *newIndex = [newIndexesByIndexName[indexName] mutableCopy];
        newIndexesByIndexName[indexName] = newIndex;

        //..and merge in the freshIndex
        [freshIndex enumerateKeysAndObjectsUsingBlock:^(id key, NSMutableSet *freshObjectsSet, BOOL *stop) {
            NSSet *existingObjectsSet = newIndex[key];
            if (existingObjectsSet != nil) [freshObjectsSet unionSet:existingObjectsSet];
            newIndex[key] = freshObjectsSet;
        }];
    }];

    //Construct the new snapshot
    BCOObjectStoreSnapshot *snapshot = [[BCOObjectStoreSnapshot alloc] init];
    snapshot->_objects = newObjects;
    snapshot->_indexDescriptions = indexDescriptions;
    snapshot->_indexesByIndexName = newIndexesByIndexName;
    snapshot->_referenceSetsByObject = newReferenceSetsByObject;

    return snapshot;
}




#pragma mark - object access
-(NSSet *)objectsForKeys:(NSArray *)keys inIndexNamed:(NSString *)indexName
{
    NSMutableSet *allObjects = [NSMutableSet new];
    for (id key in keys) {
        NSSet *objects = [self objectsForKey:key inIndexNamed:indexName];
        if (objects != nil) [allObjects unionSet:objects];
    }
    return allObjects;
}



-(NSSet *)objectsForKey:(id)key inIndexNamed:(NSString *)indexName
{
    NSDictionary *index = self.indexesByIndexName[indexName];

    NSSet *objects = index[key];

    return (objects == nil) ? [NSSet set] : objects;
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
