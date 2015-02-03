//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"

#import "BCOObjectStoreSnapshot+Query.h"
#import "BCOColumnDescription.h"
#import "BCOObjectStorageContainer.h"
#import "BCOStorageRecord.h"
#import "BCOStorageRecordsToIndekzEntriesLookUpTable.h"
#import "BCOIndekz.h"



@interface BCOObjectStoreSnapshot ()

//Storage
@property(nonatomic, readonly) BCOObjectStorageContainer *objectStorage;
//Index
@property(readonly) BCOIndekz *indekz;
//Storage->Index
@property(readonly) BCOStorageRecordsToIndekzEntriesLookUpTable *indekzEntriesByStorageRecords;

//The snap shot assumes ownership of these object so is able to modify them without copying them.
-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indekz:(BCOIndekz *)indekz indekzEntriesLookUpTable:(BCOStorageRecordsToIndekzEntriesLookUpTable *)lookupTable __attribute__((objc_designated_initializer));
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
+(BCOObjectStoreSnapshot *)snapshotWithPersistentStorePath:(NSString *)path columnDescriptions:(NSDictionary *)columnDescriptions
{
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer objectStorageWithPersistentStorePath:path];

    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storage columnDescriptions:columnDescriptions];
}



-(instancetype)init
{
    return [self initWithObjects:[NSSet set] columnDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects columnDescriptions:(NSDictionary *)columnDescriptions
{
    NSParameterAssert(objects);

    //Create storage
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer new];
    for (id object in objects) {
        [storage addObject:object];
    }

    return [self initWithObjectStorage:storage columnDescriptions:columnDescriptions];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage columnDescriptions:(NSDictionary *)columnDescriptions
{
    NSParameterAssert(storage);
    NSParameterAssert(columnDescriptions);

    //Create index
    BCOIndekz *indekz = [[BCOIndekz alloc] initWithColumnDescriptions:columnDescriptions];
    BCOStorageRecordsToIndekzEntriesLookUpTable *indekzEntriesByStorageRecords = [[BCOStorageRecordsToIndekzEntriesLookUpTable alloc] init];

    //Add each object to the indekz
    [storage enumerateStorageRecordsAndObjectsUsingBlock:^(BCOStorageRecord *record, id object, BOOL *stop) {
        BCOIndekzEntry *entry = [indekz insertEntryForRecord:record byIndexingObject:object];
        //Store the index entry by storage record
        [indekzEntriesByStorageRecords setIndekzEntry:entry forStorageRecord:record];
    }];

    return [self initWithObjectStorage:storage indekz:indekz indekzEntriesLookUpTable:indekzEntriesByStorageRecords];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indekz:(BCOIndekz *)indekz indekzEntriesLookUpTable:(BCOStorageRecordsToIndekzEntriesLookUpTable *)lookupTable
{
    //self assumes ownership of all objects
    self = [super init];
    if (self == nil) return nil;

    _objectStorage = storage;
    _indekz = indekz;
    _indekzEntriesByStorageRecords = lookupTable;

    return self;
}


#pragma mark - archiving
-(BOOL)writeToPath:(NSString *)path error:(NSError **)outError
{
    return [self.objectStorage writeToPath:path error:outError];
}



#pragma mark - properties
-(NSDictionary *)columnDescriptions
{
    return self.indekz.columnDescriptions;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    //We could optimize here by diffing against objects and only update the changes. However the cost of doing that is probably not worth it.
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects columnDescriptions:self.indekz.columnDescriptions];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
#pragma message "TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are."
    //Copy state
    BCOObjectStorageContainer *newStorage = [self.objectStorage copy];
    BCOIndekz *newIndekz = [self.indekz copy];
    BCOStorageRecordsToIndekzEntriesLookUpTable *newIndekzEntriesByStorageRecords = [self.indekzEntriesByStorageRecords copy];

    //Remove expiredObjects from...
    for (id expiredObject in expiredObjects) {
        //... storage
        BCOStorageRecord *record = [newStorage storageRecordForObject:expiredObject];
        [newStorage removeObjectForStorageRecord:record];
        //...the index by getting the entry
        BCOIndekzEntry *entry = [newIndekzEntriesByStorageRecords indekzEntryForStorageRecord:record];
        [newIndekz removeEntry:entry];
        //... the lookup table
        [newIndekzEntriesByStorageRecords removeIndekzEntryForStorageRecord:record];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        //...storage
        BCOStorageRecord *storageRecord = [newStorage addObject:freshObject];
        //...index
        BCOIndekzEntry *indekzEntry = [newIndekz insertEntryForRecord:storageRecord byIndexingObject:freshObject];
        //... the lookUp table
        [newIndekzEntriesByStorageRecords setIndekzEntry:indekzEntry forStorageRecord:storageRecord];
    }

    //Construct the new snapshot
    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:newStorage indekz:newIndekz indekzEntriesLookUpTable:newIndekzEntriesByStorageRecords];
}



#pragma mark - object access
-(NSArray *)executeQuery:(NSString *)query
{
    return [self executeQuery:query subsitutionVariable:nil objectStorage:self.objectStorage indekz:self.indekz];
}



-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable
{
    return [self executeQuery:query subsitutionVariable:subsitutionVariable objectStorage:self.objectStorage indekz:self.indekz];
}

@end
