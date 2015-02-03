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
#import "BCOStorageRecordsToQueryCatalogEntriesLookUpTable.h"
#import "BCOQueryCatalog.h"



@interface BCOObjectStoreSnapshot ()

//Storage
@property(nonatomic, readonly) BCOObjectStorageContainer *objectStorage;
//Index
@property(readonly) BCOQueryCatalog *queryCatalog;
//Storage->Index
@property(readonly) BCOStorageRecordsToQueryCatalogEntriesLookUpTable *queryCatalogEntriesByStorageRecords;

//The snap shot assumes ownership of these object so is able to modify them without copying them.
-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog queryCatalogEntriesLookUpTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)lookupTable __attribute__((objc_designated_initializer));
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
+(BCOObjectStoreSnapshot *)snapshotWithPersistentStorePath:(NSString *)path indexDescriptions:(NSDictionary *)indexDescriptions
{
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer objectStorageWithPersistentStorePath:path];

    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storage indexDescriptions:indexDescriptions];
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

    //Create index
    BCOQueryCatalog *queryCatalog = [[BCOQueryCatalog alloc] initWithIndexDescriptions:indexDescriptions];
    BCOStorageRecordsToQueryCatalogEntriesLookUpTable *queryCatalogEntriesByStorageRecords = [[BCOStorageRecordsToQueryCatalogEntriesLookUpTable alloc] init];

    //Add each object to the queryCatalog
    [storage enumerateStorageRecordsAndObjectsUsingBlock:^(BCOStorageRecord *record, id object, BOOL *stop) {
        BCOQueryCatalogEntry *entry = [queryCatalog addEntryForRecord:record byIndexingObject:object];
        //Store the index entry by storage record
        [queryCatalogEntriesByStorageRecords setQueryCatalogEntry:entry forStorageRecord:record];
    }];

    return [self initWithObjectStorage:storage queryCatalog:queryCatalog queryCatalogEntriesLookUpTable:queryCatalogEntriesByStorageRecords];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog queryCatalogEntriesLookUpTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)lookupTable
{
    //self assumes ownership of all objects
    self = [super init];
    if (self == nil) return nil;

    _objectStorage = storage;
    _queryCatalog = queryCatalog;
    _queryCatalogEntriesByStorageRecords = lookupTable;

    return self;
}


#pragma mark - archiving
-(BOOL)writeToPath:(NSString *)path error:(NSError **)outError
{
    return [self.objectStorage writeToPath:path error:outError];
}



#pragma mark - properties
-(NSDictionary *)indexDescriptions
{
    return self.queryCatalog.indexDescriptions;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    //We could optimize here by diffing against objects and only update the changes. However the cost of doing that is probably not worth it.
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.queryCatalog.indexDescriptions];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    //Copy state
    BCOObjectStorageContainer *newStorage = [self.objectStorage copy];
    BCOQueryCatalog *newQueryCatalog = [self.queryCatalog copy];
    BCOStorageRecordsToQueryCatalogEntriesLookUpTable *newQueryCatalogEntriesByStorageRecords = [self.queryCatalogEntriesByStorageRecords copy];

    //Remove expiredObjects from...
    for (id expiredObject in expiredObjects) {
        //... storage
        BCOStorageRecord *record = [newStorage storageRecordForObject:expiredObject];
        [newStorage removeObjectForStorageRecord:record];
        //...the index by getting the entry
        BCOQueryCatalogEntry *entry = [newQueryCatalogEntriesByStorageRecords queryCatalogEntryForStorageRecord:record];
        [newQueryCatalog removeEntry:entry];
        //... the lookup table
        [newQueryCatalogEntriesByStorageRecords removeQueryCatalogEntryForStorageRecord:record];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        //...storage
        BCOStorageRecord *storageRecord = [newStorage addObject:freshObject];
        //...index
        BCOQueryCatalogEntry *queryCatalogEntry = [newQueryCatalog addEntryForRecord:storageRecord byIndexingObject:freshObject];
        //... the lookUp table
        [newQueryCatalogEntriesByStorageRecords setQueryCatalogEntry:queryCatalogEntry forStorageRecord:storageRecord];
    }

    //Construct the new snapshot
    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:newStorage queryCatalog:newQueryCatalog queryCatalogEntriesLookUpTable:newQueryCatalogEntriesByStorageRecords];
}



#pragma mark - object access
-(NSArray *)executeQuery:(NSString *)query
{
    return [self executeQuery:query subsitutionVariable:nil objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable
{
    return [self executeQuery:query subsitutionVariable:subsitutionVariable objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}

@end
