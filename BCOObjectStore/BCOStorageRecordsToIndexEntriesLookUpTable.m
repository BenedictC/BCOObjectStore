//
//  BCOStorageRecordToIndexReferencesLookUpTable.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecordsToIndexEntriesLookUpTable.h"
#import "BCOIndexEntry.h"
#import "BCOStorageRecord.h"



@interface BCOStorageRecordsToIndexEntriesLookUpTable ()
{
    NSDictionary *_indexEntriesByStorageRecords;
    NSMutableDictionary *_mutableIndexEntriesByStorageRecords;
}

@end



@implementation BCOStorageRecordsToIndexEntriesLookUpTable

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexEntriesByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithIndexEntriesByStorageRecords:(NSDictionary *)indexEntriesByStorageRecords
{
    self = [super init];
    if (self == nil) return nil;

    _indexEntriesByStorageRecords = indexEntriesByStorageRecords;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    NSDictionary *entries = ([self isIndexEntriesByStorageRecordsDirty]) ? [self.indexEntriesByStorageRecords copy] : self.indexEntriesByStorageRecords;

    return  [[BCOStorageRecordsToIndexEntriesLookUpTable alloc] initWithIndexEntriesByStorageRecords:entries];
}



#pragma mark - properties
-(BOOL)isIndexEntriesByStorageRecordsDirty
{
    return (_mutableIndexEntriesByStorageRecords != nil);
}



-(NSDictionary *)indexEntriesByStorageRecords
{
    return ([self isIndexEntriesByStorageRecordsDirty]) ? _mutableIndexEntriesByStorageRecords : _indexEntriesByStorageRecords;
}



-(NSMutableDictionary *)mutableIndexEntriesByStorageRecords
{
    if (_mutableIndexEntriesByStorageRecords != nil) return _mutableIndexEntriesByStorageRecords;

    _mutableIndexEntriesByStorageRecords  = [_indexEntriesByStorageRecords mutableCopy];
    _indexEntriesByStorageRecords = nil;

    return _mutableIndexEntriesByStorageRecords;
}



#pragma mark - object access
-(void)setIndexEntry:(id)indexEntry forStorageRecord:(BCOStorageRecord *)storageRecord
{
    self.mutableIndexEntriesByStorageRecords[storageRecord] = indexEntry;
}



-(BCOIndexEntry *)indexEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    return self.indexEntriesByStorageRecords[storageRecord];
}



-(void)removeIndexEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    [self.mutableIndexEntriesByStorageRecords removeObjectForKey:storageRecord];
}

@end
