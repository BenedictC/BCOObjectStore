//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"


#import "BCOIndex.h"
#import "BCOIndexReference.h"

#import "BCOObjectStoreSnapshot+Query.h"



@interface BCOObjectKey : NSObject
@property(nonatomic, readonly) id object;
@end


@implementation BCOObjectKey

-(instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self == nil) return nil;
    _object = object;
    return self;
}



-(NSComparisonResult)compare:(BCOObjectKey *)otherKey
{
    uintptr_t obj = (uintptr_t)_object;
    uintptr_t otherObj = (uintptr_t)otherKey->_object;

    if (otherObj > obj) return NSOrderedAscending;
    if (otherObj < obj) return NSOrderedDescending;

    return NSOrderedSame;
}

@end



@interface BCOObjectStoreSnapshot ()
@property(readonly) NSDictionary *indexesByIndexName;
@property(readonly) BCOIndex *indexReferencesByObjectAddress;
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

    //Build the indexReference table
    BCOIndex *indexReferencesByObjectAddress = [BCOIndex new];

    //Build indexes
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {        

        //Create and add the index
        BCOIndex *index = [BCOIndex new];
        indexesByIndexName[indexName] = index;

        //Add each object to the index
        BCOIndexer indexer = indexDescription.indexer;
        for (id object in objects) {
            //Get the key and exit if the object shouldn't be included in this index
            id key = indexer(object);
            if (key == nil) continue;

            [index addObject:object forKey:key];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            BCOObjectKey *objectKey = [[BCOObjectKey alloc] initWithObject:object];
            [indexReferencesByObjectAddress addObject:reference forKey:objectKey];
        }
    }];
    _indexesByIndexName = indexesByIndexName;
    _indexReferencesByObjectAddress = indexReferencesByObjectAddress;

    return self;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    NSSet *oldObjects = self.objects;

#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."

    //Separate the objects into inserts and deletes
    NSMutableSet *freshObjects = [newObjects mutableCopy];
    [freshObjects minusSet:oldObjects];
    NSMutableSet *expiredObjects = [oldObjects mutableCopy];
    [expiredObjects minusSet:newObjects];

    BOOL isRebuildingMoreEfficentThanUpdating = ({
        long long numberOfRebuildOperations = newObjects.count;
        long long numberOfUpdateOperations = freshObjects.count + expiredObjects.count;
        numberOfRebuildOperations < numberOfUpdateOperations;
    });
    if (isRebuildingMoreEfficentThanUpdating) {
        return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.indexDescriptions];
    }

    return [self snapshotByRemovingObjects:expiredObjects addingObjects:freshObjects];
}



-(BCOObjectStoreSnapshot *)snapshotByRemovingObjects:(NSSet *)expiredObjects addingObjects:(NSSet *)freshObjects
{
    NSDictionary *indexDescriptions = self.indexDescriptions;
    NSSet *oldObjects = self.objects;

    NSMutableSet *newObjects = [oldObjects mutableCopy];
    //Perfrom a deep copy of the indexes
    BCOIndex *newIndexEntryReferencesByObject = [self.indexReferencesByObjectAddress copy];
    NSMutableDictionary *newIndexesByIndexName = ({
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
            dict[indexName] = [index copy];
        }];
        dict;
    });

    //Remove expired objects from...
    for (id nonCanonicalExpiredObject in expiredObjects) {
        id expiredObject = [oldObjects member:nonCanonicalExpiredObject];
        if (expiredObject == nil) {
            NSLog(@"Attempting to remove an object not in the store");
            continue;
        }

        //.. all objects
        [newObjects removeObject:expiredObject];

        //...each index by enumerating the objects indexReferences
        BCOObjectKey *objectKey = [[BCOObjectKey alloc] initWithObject:expiredObject];
        NSSet *references = [newIndexEntryReferencesByObject objectsForKey:objectKey];
        for (BCOIndexReference *reference in references) {
            BCOIndex *index = newIndexesByIndexName[reference.indexName];
            [index removeObject:expiredObject forKey:reference.key];
        }

        //...the reference set (this has to happen after removing the object from the indexes)
        [newIndexEntryReferencesByObject removeObject:expiredObject forKey:objectKey];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        id existingObject = [oldObjects member:freshObject];
        if (existingObject != nil) {
            NSLog(@"Store already contains object");
            continue;
        }

        //...all objects
        [newObjects addObject:freshObject];


        //...each index
        BCOObjectKey *objectKey = [[BCOObjectKey alloc] initWithObject:freshObject];
        [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
            //Generate a key
            id key = indexDescription.indexer(freshObject);
            //Get the key and exit if the object shouldn't be included in this index
            if (key == nil) return;

            //Add the object to the index entry
            BCOIndex *indeks = newIndexesByIndexName[indexName];
            [indeks addObject:freshObject forKey:key];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            [newIndexEntryReferencesByObject addObject:reference forKey:objectKey];
        }];
    }

    //Construct the new snapshot
    BCOObjectStoreSnapshot *snapshot = [[BCOObjectStoreSnapshot alloc] init];
    snapshot->_indexDescriptions = indexDescriptions;
    snapshot->_objects = newObjects;
    snapshot->_indexesByIndexName = newIndexesByIndexName;
    snapshot->_indexReferencesByObjectAddress = newIndexEntryReferencesByObject;

    return snapshot;
}



#pragma mark - object access
-(NSArray *)executeQuery:(NSString *)query
{
    return [self executeQuery:query subsitutionVariable:nil objects:self.objects indexes:self.indexesByIndexName];
}



-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable
{
    return [self executeQuery:query subsitutionVariable:subsitutionVariable objects:self.objects indexes:self.indexesByIndexName];
}

@end
