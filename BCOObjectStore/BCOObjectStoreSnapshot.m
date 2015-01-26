//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"
#import "BCOInMemoryObjectStorage.h"

#import "BCOIndex.h"
#import "BCOIndexReference.h"

#import "BCOObjectStoreSnapshot+Query.h"



@interface BCOObjectStoreSnapshot ()

@property(readonly) NSDictionary *indexDescriptions;
@property(nonatomic, readonly) BCOInMemoryObjectStorage *objectStorage;

//currently: objectKey:indexReferences
//currently: indexKey:objectsSet

//better:    object -> uuid         uuid:indexReference      uuid -> object (this will allow the objects to be searched without being present)
//better:    indexKey:uuidsSet
@property(readonly) BCOIndex *indexReferencesByObjectKey;


@property(readonly) NSDictionary *indexesByIndexName;
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
+(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:objects indexDescriptions:indexDescriptions];
}



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
    _objectStorage = [BCOInMemoryObjectStorage new];
    _indexDescriptions = [indexDescriptions copy];

    //Build indexes
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        //Create and add the index
        BCOIndex *index = [[BCOIndex alloc] initWithComparator:indexDescription.keyComparator];
        indexesByIndexName[indexName] = index;
    }];

    //Keep track of which indexes contain each object
    BCOIndex *indexReferencesByLookUpToken = [[BCOIndex alloc] initWithComparator:BCOObjectStorageLookUpTokenComparator];

    //Add each object to each index
    for (id object in objects) {
        //Insert the object into the storage
        BCOObjectStorageLookUpToken *token = [_objectStorage addObject:object];

        [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
            //Get the key and exit if the object shouldn't be included in this index
            id key = indexDescription.indexKeyGenerator(object);
            if (key == nil) return;

            //Get the index and dd the token to it
            BCOIndex *index = indexesByIndexName[indexName];
            [index addObject:token forKey:key];

            //Add an indexReference to the referencesSet for the token
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            [_indexReferencesByObjectKey addObject:reference forKey:token];
        }];
    }

    _indexesByIndexName = indexesByIndexName;
    _indexReferencesByObjectKey = indexReferencesByLookUpToken;

    return self;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.indexDescriptions];

#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
//    NSSet *oldObjects = self.objectStorage.objects;
//
//    //Separate the objects into inserts and deletes
//    NSMutableSet *freshObjects = [newObjects mutableCopy];
//    [freshObjects minusSet:oldObjects];
//    NSMutableSet *expiredObjects = [oldObjects mutableCopy];
//    [expiredObjects minusSet:newObjects];
//
//    BOOL isRebuildingMoreEfficentThanUpdating = ({
//        long long numberOfRebuildOperations = newObjects.count;
//        long long numberOfUpdateOperations = freshObjects.count + expiredObjects.count;
//        numberOfRebuildOperations < numberOfUpdateOperations;
//    });
//    if (isRebuildingMoreEfficentThanUpdating) {
//        return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.indexDescriptions];
//    }
//
//    return [self snapshotByInsertingObjects:freshObjects deletingObjects:expiredObjects];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    NSDictionary *indexDescriptions = self.indexDescriptions;
    BCOInMemoryObjectStorage *oldStorage = self.objectStorage;
    BCOInMemoryObjectStorage *newStorage = oldStorage.copy;

    //Perfrom a deep copy of the indexes
    BCOIndex *newIndexEntryReferencesByToken = [self.indexReferencesByObjectKey copy];
    NSMutableDictionary *newIndexesByIndexName = ({
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
            dict[indexName] = [index copy];
        }];
        dict;
    });

    //Remove expired objects from...
    for (id expiredObject in expiredObjects) {
        BCOObjectStorageLookUpToken *token = [newStorage lookupTokenForObject:expiredObject];
        if (token == nil) {
            NSLog(@"Attempting to remove an object not in the store");
            continue;
        }

        //... storage
        [newStorage removeObject:expiredObject];

        //...each index by enumerating the indexRefrenences
        NSSet *references = [newIndexEntryReferencesByToken objectsForKey:token];
        for (BCOIndexReference *reference in references) {
            BCOIndex *index = newIndexesByIndexName[reference.indexName];
            [index removeObject:token forKey:reference.key];

            //...the reference set (this has to happen after removing the object from the indexes)
            [newIndexEntryReferencesByToken removeObject:reference forKey:token];
        }

    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        BCOObjectStorageLookUpToken *existingToken = [newStorage lookupTokenForObject:freshObject];
        if (existingToken != nil) {
            NSLog(@"Store already contains object");
            continue;
        }

        //...all objects
        BCOObjectStorageLookUpToken *token = [newStorage addObject:freshObject];

        //...each index
        [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
            //Generate a key
            id key = indexDescription.indexKeyGenerator(freshObject);
            //Get the key and exit if the object shouldn't be included in this index
            if (key == nil) return;

            //Add the object to the index entry
            BCOIndex *index = newIndexesByIndexName[indexName];
            [index addObject:token forKey:key];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            [newIndexEntryReferencesByToken addObject:reference forKey:token];
        }];
    }

    //Construct the new snapshot
    BCOObjectStoreSnapshot *snapshot = [[BCOObjectStoreSnapshot alloc] init];
    snapshot->_indexDescriptions = indexDescriptions;
    snapshot->_objectStorage = newStorage;
    snapshot->_indexesByIndexName = newIndexesByIndexName;
    snapshot->_indexReferencesByObjectKey = newIndexEntryReferencesByToken;

    return snapshot;
}



-(BCOObjectStoreSnapshot *)snapshotByAddingIndexDescription:(BCOIndexDescription *)indexDescription withIndexName:(NSString *)indexName
{
    NSMutableDictionary *indexDescriptions = [self.indexDescriptions mutableCopy];
    indexDescriptions[indexName] = indexDescription;
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:self.objectStorage.allObjects indexDescriptions:indexDescriptions];
}



#pragma mark - object access
-(NSArray *)executeQuery:(NSString *)query
{
    return [self executeQuery:query subsitutionVariable:nil objectStorage:self.objectStorage indexes:self.indexesByIndexName];
}



-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable
{
    return [self executeQuery:query subsitutionVariable:subsitutionVariable objectStorage:self.objectStorage indexes:self.indexesByIndexName];
}

@end
