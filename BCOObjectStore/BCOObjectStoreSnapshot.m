//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"

#import "BCOObjectStoreSnapshot+Query.h"
#import "BCOIndexDescription.h"
#import "BCOObjectStorageContainer.h"
#import "BCOStorageRecord.h"
#import "BCOIndexReferencesLookUpTable.h"
#import "BCOIndex.h"



@interface BCOObjectStoreSnapshot ()

//Storage
@property(nonatomic, readonly) BCOObjectStorageContainer *objectStorage;
//Indexes
@property(readonly) NSDictionary *indexesByIndexName;
//Storage->Indexes
@property(readonly) BCOIndexReferencesLookUpTable *indexReferencesByStorageRecords;

//The snap shot assumes ownership of these object so is able to modify them without copying them.
-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indexes:(NSDictionary *)indexes indexReferencesLookUpTable:(BCOIndexReferencesLookUpTable *)lookupTable __attribute__((objc_designated_initializer));
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

    //Create storage
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer new];
    for (id object in objects) {
        [storage addObject:object];
    }

    return [self initWithObjectStorage:storage indexDescriptions:indexDescriptions];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(storage);
    NSParameterAssert(indexDescriptions);

    //Create indexes
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        //Create and add the index
        BCOIndex *index = [[BCOIndex alloc] initWithIndexDescription:indexDescription];
        indexesByIndexName[indexName] = index;
    }];

    //Keep track of which indexes contain each object
    BCOIndexReferencesLookUpTable *indexReferencesByStorageRecords = [[BCOIndexReferencesLookUpTable alloc] init];

    //Add each object to each index
    [storage enumerateStorageRecordsAndObjectsUsingBlock:^(BCOStorageRecord *storageRecord, id object, BOOL *stop) {
        [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
            //Get the key and exit if the object shouldn't be included in this index
            id key = indexDescription.indexKeyGenerator(object);
            if (key == nil) return;

            //Get the index and add the token to it
            BCOIndex *index = indexesByIndexName[indexName];
            [index addObject:storageRecord forKey:key];

            //Add an indexReference to the referencesSet for the token
            [indexReferencesByStorageRecords addIndexReferenceWithIndexName:indexName indexKey:key forStorageRecord:storageRecord];
        }];
    }];

    return [self initWithObjectStorage:storage indexes:indexesByIndexName indexReferencesLookUpTable:indexReferencesByStorageRecords];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indexes:(NSDictionary *)indexes indexReferencesLookUpTable:(BCOIndexReferencesLookUpTable *)lookupTable
{
    self = [super init];
    if (self == nil) return nil;

    _objectStorage = storage;
    _indexesByIndexName = indexes;
    _indexReferencesByStorageRecords = lookupTable;

    return self;
}


#pragma mark - archiving
-(NSData *)snapshotArchive
{
    return [self.objectStorage dataRepresentation];
}



+(BCOObjectStoreSnapshot *)snapshotFromSnapshotArchive:(NSData *)representation indexDescriptions:(NSDictionary *)indexDescriptions
{
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer objectStorageWithData:representation];    

    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storage indexDescriptions:indexDescriptions];
}



#pragma mark - properties
-(NSDictionary *)indexDescriptions
{
    NSMutableDictionary *indexDescriptions = [NSMutableDictionary new];
    [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        indexDescriptions[indexName] = index.indexDescription;
    }];

    return indexDescriptions;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.indexDescriptions];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    //Copy state
    BCOObjectStorageContainer *newStorage = [self.objectStorage copy];
    BCOIndexReferencesLookUpTable *newIndexReferencesByStorageRecords = [self.indexReferencesByStorageRecords copy];
    NSMutableDictionary *newIndexesByIndexName = ({ //Perfrom a deep copy of the indexes
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
            dict[indexName] = [index copy];
        }];
        dict;
    });

    //Remove expiredObjects from...
    for (id expiredObject in expiredObjects) {
        BCOStorageRecord *record = [newStorage storageRecordForObject:expiredObject];
        if (record == nil) {
            NSLog(@"Attempting to remove an object not in the store");
            continue;
        }

        //... storage
        [newStorage removeObjectForStorageRecord:record];

        //...each index by enumerating the indexRefrenences
        [newIndexReferencesByStorageRecords enumerateIndexReferencesForStorageRecord:record usingBlock:^(NSString *indexName, NSString *indexKey) {
            BCOIndex *index = newIndexesByIndexName[indexName];
            [index removeObject:record forKey:indexKey];
        }];

        //... the lookup table
        [newIndexReferencesByStorageRecords removeIndexReferencesForStorageRecord:record];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        BCOStorageRecord *existingToken = [newStorage storageRecordForObject:freshObject];
        if (existingToken != nil) {
            NSLog(@"Store already contains object");
            continue;
        }

        //...storage
        BCOStorageRecord *storageRecord = [newStorage addObject:freshObject];

        //...each index
        [newIndexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
            //Generate a key
            id key = index.indexDescription.indexKeyGenerator(freshObject);
            //Get the key and exit if the object shouldn't be included in this index
            if (key == nil) return;

            //Add the object to the index entry
            [index addObject:storageRecord forKey:key];

            //... the lookUp table
            [newIndexReferencesByStorageRecords addIndexReferenceWithIndexName:indexName indexKey:key forStorageRecord:storageRecord];
        }];
    }

    //Construct the new snapshot
    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:newStorage indexes:newIndexesByIndexName indexReferencesLookUpTable:newIndexReferencesByStorageRecords];
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
