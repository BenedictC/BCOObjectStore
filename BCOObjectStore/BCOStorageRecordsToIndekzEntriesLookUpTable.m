//
//  BCOStorageRecordToIndekzReferencesLookUpTable.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecordsToIndekzEntriesLookUpTable.h"
#import "BCOIndekzEntry.h"
#import "BCOStorageRecord.h"



@interface BCOStorageRecordsToIndekzEntriesLookUpTable ()
{
    NSDictionary *_indekzEntriesByStorageRecords;
    NSMutableDictionary *_mutableIndekzEntriesByStorageRecords;
}

@end



@implementation BCOStorageRecordsToIndekzEntriesLookUpTable

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndekzEntriesByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithIndekzEntriesByStorageRecords:(NSDictionary *)indekzEntriesByStorageRecords
{
    self = [super init];
    if (self == nil) return nil;

    _indekzEntriesByStorageRecords = indekzEntriesByStorageRecords;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    NSDictionary *entries = ([self isIndekzEntriesByStorageRecordsDirty]) ? [self.indekzEntriesByStorageRecords copy] : self.indekzEntriesByStorageRecords;

    return  [[BCOStorageRecordsToIndekzEntriesLookUpTable alloc] initWithIndekzEntriesByStorageRecords:entries];
}



#pragma mark - properties
-(BOOL)isIndekzEntriesByStorageRecordsDirty
{
    return (_mutableIndekzEntriesByStorageRecords != nil);
}



-(NSDictionary *)indekzEntriesByStorageRecords
{
    return ([self isIndekzEntriesByStorageRecordsDirty]) ? _mutableIndekzEntriesByStorageRecords : _indekzEntriesByStorageRecords;
}



-(NSMutableDictionary *)mutableIndekzEntriesByStorageRecords
{
    if (_mutableIndekzEntriesByStorageRecords != nil) return _mutableIndekzEntriesByStorageRecords;

    _mutableIndekzEntriesByStorageRecords  = [_indekzEntriesByStorageRecords mutableCopy];
    _indekzEntriesByStorageRecords = nil;

    return _mutableIndekzEntriesByStorageRecords;
}



#pragma mark - object access
-(void)setIndekzEntry:(id)indekzEntry forStorageRecord:(BCOStorageRecord *)storageRecord
{
    self.mutableIndekzEntriesByStorageRecords[storageRecord] = indekzEntry;
}



-(BCOIndekzEntry *)indekzEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    return self.indekzEntriesByStorageRecords[storageRecord];
}



-(void)removeIndekzEntryForStorageRecord:(BCOStorageRecord *)storageRecord
{
    [self.mutableIndekzEntriesByStorageRecords removeObjectForKey:storageRecord];
}

@end
