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
{
    NSDictionary *_queryCatalogEntriesByStorageRecords;
    NSMutableDictionary *_mutableQueryCatalogEntriesByStorageRecords;
}

@end



@implementation BCOStorageRecordsToQueryCatalogEntriesLookUpTable

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithQueryCatalogEntriesByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithQueryCatalogEntriesByStorageRecords:(NSDictionary *)queryCatalogEntriesByStorageRecords
{
    self = [super init];
    if (self == nil) return nil;

    _queryCatalogEntriesByStorageRecords = queryCatalogEntriesByStorageRecords;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    NSDictionary *entries = ([self isQueryCatalogEntriesByStorageRecordsDirty]) ? [self.queryCatalogEntriesByStorageRecords copy] : self.queryCatalogEntriesByStorageRecords;

    return  [[BCOStorageRecordsToQueryCatalogEntriesLookUpTable alloc] initWithQueryCatalogEntriesByStorageRecords:entries];
}



#pragma mark - properties
-(BOOL)isQueryCatalogEntriesByStorageRecordsDirty
{
    return (_mutableQueryCatalogEntriesByStorageRecords != nil);
}



-(NSDictionary *)queryCatalogEntriesByStorageRecords
{
    return ([self isQueryCatalogEntriesByStorageRecordsDirty]) ? _mutableQueryCatalogEntriesByStorageRecords : _queryCatalogEntriesByStorageRecords;
}



-(NSMutableDictionary *)mutableQueryCatalogEntriesByStorageRecords
{
    if (_mutableQueryCatalogEntriesByStorageRecords != nil) return _mutableQueryCatalogEntriesByStorageRecords;

    _mutableQueryCatalogEntriesByStorageRecords  = [_queryCatalogEntriesByStorageRecords mutableCopy];
    _queryCatalogEntriesByStorageRecords = nil;

    return _mutableQueryCatalogEntriesByStorageRecords;
}



#pragma mark - object access
-(void)setQueryCatalogEntry:(id)queryCatalogEntry forStorageRecord:(BCOStorageRecord *)storageRecord
{
    self.mutableQueryCatalogEntriesByStorageRecords[storageRecord] = queryCatalogEntry;
}



-(BCOQueryCatalogEntry *)queryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    return self.queryCatalogEntriesByStorageRecords[storageRecord];
}



-(void)removeQueryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    [self.mutableQueryCatalogEntriesByStorageRecords removeObjectForKey:storageRecord];
}

@end
