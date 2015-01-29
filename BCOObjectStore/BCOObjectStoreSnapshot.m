//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"

#import "BCOObjectStoreSnapshot+Query.h"
#import "BCOIndexColumnDescription.h"
#import "BCOObjectStorageContainer.h"
#import "BCOStorageRecord.h"
#import "BCOStorageRecordsToIndexEntriesLookUpTable.h"
#import "BCOIndex.h"



@interface BCOObjectStoreSnapshot ()

//Storage
@property(nonatomic, readonly) BCOObjectStorageContainer *objectStorage;
//Index
@property(readonly) BCOIndex *index;
//Storage->Index
@property(readonly) BCOStorageRecordsToIndexEntriesLookUpTable *indexEntriesByStorageRecords;

//The snap shot assumes ownership of these object so is able to modify them without copying them.
-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage index:(BCOIndex *)index indexEntriesLookUpTable:(BCOStorageRecordsToIndexEntriesLookUpTable *)lookupTable __attribute__((objc_designated_initializer));
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
+(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)objects indexColumnDescriptions:(NSDictionary *)indexColumnDescriptions
{
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:objects indexColumnDescriptions:indexColumnDescriptions];
}



-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexColumnDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexColumnDescriptions:(NSDictionary *)indexColumnDescriptions
{
    NSParameterAssert(objects);

    //Create storage
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer new];
    for (id object in objects) {
        [storage addObject:object];
    }

    return [self initWithObjectStorage:storage indexColumnDescriptions:indexColumnDescriptions];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indexColumnDescriptions:(NSDictionary *)indexColumnDescriptions
{
    NSParameterAssert(storage);
    NSParameterAssert(indexColumnDescriptions);

    //Create index
    BCOIndex *index = [[BCOIndex alloc] initWithIndexColumnDescriptions:indexColumnDescriptions];
    BCOStorageRecordsToIndexEntriesLookUpTable *indexEntriesByStorageRecords = [[BCOStorageRecordsToIndexEntriesLookUpTable alloc] init];

    //Add each object to the index
    [storage enumerateStorageRecordsAndObjectsUsingBlock:^(BCOStorageRecord *record, id object, BOOL *stop) {
        BCOIndexEntry *entry = [index insertEntryForRecord:record byIndexingObject:object];
        //Store the index entry by storage record
        [indexEntriesByStorageRecords setIndexEntry:entry forStorageRecord:record];
    }];

    return [self initWithObjectStorage:storage index:index indexEntriesLookUpTable:indexEntriesByStorageRecords];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage index:(BCOIndex *)index indexEntriesLookUpTable:(BCOStorageRecordsToIndexEntriesLookUpTable *)lookupTable
{
    //self assumes ownership of all objects
    self = [super init];
    if (self == nil) return nil;

    _objectStorage = storage;
    _index = index;
    _indexEntriesByStorageRecords = lookupTable;

    return self;
}


#pragma mark - archiving
-(NSData *)snapshotArchive
{
    return [self.objectStorage dataRepresentation];
}



+(BCOObjectStoreSnapshot *)snapshotFromSnapshotArchive:(NSData *)representation indexColumnDescriptions:(NSDictionary *)indexColumnDescriptions
{
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer objectStorageWithData:representation];    

    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storage indexColumnDescriptions:indexColumnDescriptions];
}



#pragma mark - properties
-(NSDictionary *)indexColumnDescriptions
{
    return self.index.indexColumnDescriptions;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexColumnDescriptions:self.indexColumnDescriptions];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    //Copy state
    BCOObjectStorageContainer *newStorage = [self.objectStorage copy];
    BCOIndex *newIndex = [self.index copy];
    BCOStorageRecordsToIndexEntriesLookUpTable *newIndexEntriesByStorageRecords = [self.indexEntriesByStorageRecords copy];

    
    //Remove expiredObjects from...
    for (id expiredObject in expiredObjects) {
        //... storage
        BCOStorageRecord *record = [newStorage storageRecordForObject:expiredObject];
        [newStorage removeObjectForStorageRecord:record];
        //...the index by getting the entry
        BCOIndexEntry *entry = [newIndexEntriesByStorageRecords indexEntryForStorageRecord:record];
        [newIndex removeEntry:entry];
        //... the lookup table
        [newIndexEntriesByStorageRecords removeIndexEntryForStorageRecord:record];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        //...storage
        BCOStorageRecord *storageRecord = [newStorage addObject:freshObject];
        //...index
        BCOIndexEntry *indexEntry = [newIndex insertEntryForRecord:storageRecord byIndexingObject:freshObject];
        //... the lookUp table
        [newIndexEntriesByStorageRecords setIndexEntry:indexEntry forStorageRecord:storageRecord];
    }

    //Construct the new snapshot
    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:newStorage index:newIndex indexEntriesLookUpTable:newIndexEntriesByStorageRecords];
}



#pragma mark - object access
-(NSArray *)executeQuery:(NSString *)query
{
    return [self executeQuery:query subsitutionVariable:nil objectStorage:self.objectStorage index:self.index];
}



-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable
{
    return [self executeQuery:query subsitutionVariable:subsitutionVariable objectStorage:self.objectStorage index:self.index];
}

@end
