//
//  BCOIndexReferencesLookUpTable.m
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOIndexReferencesLookUpTable.h"
#import "BCOIndexReference.h"
#import "BCOStorageRecord.h"



@interface BCOIndexReferencesLookUpTable ()
@property(nonatomic, readonly) NSMutableDictionary *indexReferencesByStorageRecords;
@end



@implementation BCOIndexReferencesLookUpTable

-(instancetype)init
{
    return [self initWithIndexReferencesByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithIndexReferencesByStorageRecords:(NSMutableDictionary *)indexReferencesByStorageRecords
{
//BCOIndexReferencesLookUpTable assumes ownership of indexReferencesByStorageRecords and will modify it
    self = [super init];
    if (self == nil) return nil;

    _indexReferencesByStorageRecords = indexReferencesByStorageRecords;

    return self;
}


-(id)copyWithZone:(NSZone *)zone
{
    //Perform a deep copy
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [self.indexReferencesByStorageRecords enumerateKeysAndObjectsUsingBlock:^(BCOStorageRecord *record, NSSet *references, BOOL *stop) {
        dict[record] = [references mutableCopy];
    }];

    return  [[BCOIndexReferencesLookUpTable alloc] initWithIndexReferencesByStorageRecords:dict];
}



-(void)addIndexReferenceWithIndexName:(NSString *)indexName indexKey:(NSString *)indexKey forStorageRecord:(BCOStorageRecord *)storageRecord
{
    NSMutableSet *indexReferences = self.indexReferencesByStorageRecords[storageRecord];
    if (indexReferences == nil) {
        indexReferences = [NSMutableSet new];
        self.indexReferencesByStorageRecords[storageRecord] = indexReferences;
    }

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
    [self.indexReferencesByStorageRecords removeObjectForKey:storageRecord];
}

@end
