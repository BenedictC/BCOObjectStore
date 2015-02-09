//
//  BCOStorageRecordsToQueryCatalogEntriesLookUpTable.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecordsToQueryCatalogEntriesLookUpTable.h"
#import "BCOQueryCatalogEntry.h"
#import "BCOStorageRecord.h"



@interface BCOStorageRecordsToQueryCatalogEntriesLookUpTable ()

@property(nonatomic, readonly) NSDictionary *queryCatalogEntriesByStorageRecords;
@property(nonatomic, readonly) BCOStorageRecordsToQueryCatalogEntriesLookUpTable *previousTable;

@end



@implementation BCOStorageRecordsToQueryCatalogEntriesLookUpTable

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithQueryCatalogEntriesByStorageRecords:nil previousTable:nil];
}



-(instancetype)initWithQueryCatalogEntriesByStorageRecords:(NSDictionary *)queryCatalogEntriesByStorageRecords previousTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)previousTable
{
    self = [super init];
    if (self == nil) return nil;

    _queryCatalogEntriesByStorageRecords = queryCatalogEntriesByStorageRecords;
    _previousTable = previousTable;

    return self;
}



#pragma mark - object access
-(BCOQueryCatalogEntry *)queryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    id entry = self.queryCatalogEntriesByStorageRecords[storageRecord];
    if (entry != nil) {
        return (entry == [NSNull null]) ? nil : entry;
    }

    return [self.previousTable queryCatalogEntryForStorageRecord:storageRecord];
}

@end



@interface BCOStorageRecordsToQueryCatalogEntriesLookUpTableBuilder ()
@property(nonatomic, readonly) NSMutableDictionary *mutableQueryCatalogEntriesByStorageRecords;
@property(nonatomic, readonly) BCOStorageRecordsToQueryCatalogEntriesLookUpTable *previousTable;

@end



@implementation BCOStorageRecordsToQueryCatalogEntriesLookUpTableBuilder

#pragma mark - instance life cycle
+(instancetype)builderWithPreviousTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)table
{
    return [[BCOStorageRecordsToQueryCatalogEntriesLookUpTableBuilder alloc] initWithPreviousTable:table];
}



-(instancetype)init
{
    return [self initWithPreviousTable:nil];
}



-(instancetype)initWithPreviousTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)table
{
    self = [super init];
    if (self == nil) return nil;

    _previousTable = table;
    _mutableQueryCatalogEntriesByStorageRecords = [NSMutableDictionary new];

    return self;
}



#pragma mark - data updating
-(void)setQueryCatalogEntry:(BCOQueryCatalogEntry *)queryCatalogEntry forStorageRecord:(BCOStorageRecord *)storageRecord
{
    self.mutableQueryCatalogEntriesByStorageRecords[storageRecord] = queryCatalogEntry;
}



-(void)removeQueryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    self.mutableQueryCatalogEntriesByStorageRecords[storageRecord] = [NSNull null];
}



#pragma mark - generation
-(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)finalize
{
    NSAssert(_mutableQueryCatalogEntriesByStorageRecords != nil, @"Attempted to re-finalize an object.");

    BCOStorageRecordsToQueryCatalogEntriesLookUpTable *table = [[BCOStorageRecordsToQueryCatalogEntriesLookUpTable alloc] initWithQueryCatalogEntriesByStorageRecords:self.mutableQueryCatalogEntriesByStorageRecords previousTable:self.previousTable];
    _mutableQueryCatalogEntriesByStorageRecords = nil;
    _previousTable = nil;

    return table;
}

@end
