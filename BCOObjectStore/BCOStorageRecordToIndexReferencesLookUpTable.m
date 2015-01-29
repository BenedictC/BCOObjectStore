//
//  BCOStorageRecordToIndexReferencesLookUpTable.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecordToIndexReferencesLookUpTable.h"
#import "BCOIndexReference.h"
#import "BCOStorageRecord.h"



@interface BCOStorageRecordToIndexReferencesLookUpTable ()
{
    NSDictionary *_indexReferencesByStorageRecords;
    NSMutableDictionary *_mutableIndexReferencesByStorageRecords;
}

@property(nonatomic, readonly) NSMutableSet *dirtyIndexReferencesSets;

@end



@implementation BCOStorageRecordToIndexReferencesLookUpTable

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexReferencesByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithIndexReferencesByStorageRecords:(NSDictionary *)indexReferencesByStorageRecords
{
    self = [super init];
    if (self == nil) return nil;

    _indexReferencesByStorageRecords = indexReferencesByStorageRecords;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    if (![self isIndexReferencesByStorageRecordsDirty]) {
        return [[BCOStorageRecordToIndexReferencesLookUpTable alloc] initWithIndexReferencesByStorageRecords:self.indexReferencesByStorageRecords];
    }

    //Perform a deep copy and copy any sets that we have write access to
    NSSet *dirtySets = self.dirtyIndexReferencesSets;
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [self.indexReferencesByStorageRecords enumerateKeysAndObjectsUsingBlock:^(BCOStorageRecord *record, NSMutableSet *references, BOOL *stop) {
        BOOL mustCopy = [dirtySets containsObject:references];

        NSSet *shareableSet = (mustCopy) ? [references copy] : references; //We set an immutable set so that if we've made a mistake and try to write to it we'll crash.
        dict[record] = shareableSet;
    }];

    return  [[BCOStorageRecordToIndexReferencesLookUpTable alloc] initWithIndexReferencesByStorageRecords:dict];
}



#pragma mark - properties
-(BOOL)isIndexReferencesByStorageRecordsDirty
{
    return (_mutableIndexReferencesByStorageRecords != nil);
}



-(NSDictionary *)indexReferencesByStorageRecords
{
    return ([self isIndexReferencesByStorageRecordsDirty]) ? _mutableIndexReferencesByStorageRecords : _indexReferencesByStorageRecords;
}



-(NSMutableDictionary *)mutableIndexReferencesByStorageRecords
{
    if (_mutableIndexReferencesByStorageRecords != nil) return _mutableIndexReferencesByStorageRecords;

    _mutableIndexReferencesByStorageRecords  = [_indexReferencesByStorageRecords mutableCopy];
    _indexReferencesByStorageRecords = nil;

    return _mutableIndexReferencesByStorageRecords;
}



#pragma mark - object access
-(NSMutableSet *)mutableIndexReferenceSetForStorageRecord:(BCOStorageRecord *)storageRecord
{
    NSMutableSet *indexReferences = self.mutableIndexReferencesByStorageRecords[storageRecord];

    BOOL isNew = indexReferences == nil;
    if (isNew) {
        indexReferences = [NSMutableSet new];
        [self.dirtyIndexReferencesSets addObject:indexReferences];
        return indexReferences;
    }

    //Done!
    BOOL isAlreadyDirty = [self.dirtyIndexReferencesSets containsObject:indexReferences];
    if (isAlreadyDirty) return indexReferences;

    //Duplicate the owned set
    NSMutableSet *ownedIndexReferences = [indexReferences mutableCopy];
    [self.dirtyIndexReferencesSets addObject:ownedIndexReferences];
    self.mutableIndexReferencesByStorageRecords[storageRecord] = ownedIndexReferences;

    return ownedIndexReferences;
}



-(void)addIndexReferenceWithIndexName:(NSString *)indexName indexKey:(NSString *)indexKey forStorageRecord:(BCOStorageRecord *)storageRecord
{
    NSMutableSet *indexReferences = [self mutableIndexReferenceSetForStorageRecord:storageRecord];
    BCOIndexReference *indexReference = [[BCOIndexReference alloc] initWithIndexName:indexName key:indexKey];
    [indexReferences addObject:indexReference];
}



-(void)enumerateIndexReferencesForStorageRecord:(BCOStorageRecord *)storageRecord usingBlock:(void(^)(NSString *indexName, NSString *indexKey))block
{
    NSSet *indexReferences = self.indexReferencesByStorageRecords[storageRecord];
    for (BCOIndexReference *indexReference in indexReferences) {
        block(indexReference.indexName, indexReference.key);
    }
}



-(void)removeIndexReferencesForStorageRecord:(BCOStorageRecord *)storageRecord
{
    [self.mutableIndexReferencesByStorageRecords removeObjectForKey:storageRecord];
}

@end
