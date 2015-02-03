//
//  BCOQueryCatalog.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 29/01/2015.
//
//

#import "BCOQueryCatalog.h"
#import "BCOIndex.h"
#import "BCOQueryCatalogEntry.h"



@interface BCOQueryCatalog ()

@property(nonatomic, readonly) NSMutableDictionary *mutableIndexsByName;

@end



@implementation BCOQueryCatalog

#pragma mark - instance life cycle
-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions
{
    //Create and add the index
    NSMutableDictionary *mutableIndexsByName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        BCOIndex *newIndex = [[BCOIndex alloc] initWithIndexDescription:indexDescription];
        mutableIndexsByName[indexName] = newIndex;
    }];

    return [self initWithIndexDescriptions:indexDescriptions mutableIndexsByName:mutableIndexsByName];
}



-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions mutableIndexsByName:(NSMutableDictionary *)mutableIndexsByName
{
    NSParameterAssert(indexDescriptions);
    NSParameterAssert(mutableIndexsByName);

    self = [super init];
    if (self == nil) return nil;

    _indexDescriptions = [indexDescriptions copy];
    _mutableIndexsByName = mutableIndexsByName;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    //Perfrom a deep copy of the indexs
    NSMutableDictionary *mutableIndexsByName = [NSMutableDictionary new];
    [self.mutableIndexsByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        mutableIndexsByName[indexName] = [index copy];
    }];

    return [[BCOQueryCatalog alloc] initWithIndexDescriptions:self.indexDescriptions mutableIndexsByName:mutableIndexsByName];
}



#pragma mark - properties
-(NSDictionary *)indexsByName
{
    return _mutableIndexsByName;
}



#pragma mark - access
-(BCOQueryCatalogEntry *)addEntryForRecord:(id)record byIndexingObject:(id)object
{
    BCOQueryCatalogEntry *entry = [[BCOQueryCatalogEntry alloc] initWithRecord:record];
    [self.indexsByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        id value = [index generateIndexValueForObject:object];
        if (value == nil) return;

        //Add the record to the index
        [index addRecord:record forIndexValue:value];

        //Add a reference for the indexName:value pair to the entry.
        entry.valuesByIndexName[indexName] = value;
    }];

    return entry;
}



-(void)removeEntry:(BCOQueryCatalogEntry *)queryCatalogEntry
{
    NSDictionary *mutableIndexs = self.mutableIndexsByName;
    [queryCatalogEntry.valuesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, id value, BOOL *stop) {
        BCOIndex *index = mutableIndexs[indexName];
        [index removeRecord:queryCatalogEntry.record forIndexValue:value];
    }];
}



-(void)enumerateKeysAndObjectsUsingBlock:(void(^)(NSString *indexName, BCOIndex *index, BOOL *stop))block
{
    [self.mutableIndexsByName enumerateKeysAndObjectsUsingBlock:block];
}



#pragma mark - modifying
-(NSSet *)recordsInIndex:(NSString *)indexName forValue:(id)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsForValue:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName forValuesNotEqualToValue:(id)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsWithValueNotEqualTo:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName forValuesInSet:(NSSet *)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsForValuesInSet:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName forValuesNotInSet:(NSSet *)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsForValuesNotInSet:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName lessThanValue:(id)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsWithValueLessThan:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName lessThanOrEqualToValue:(id)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsWithValueLessThanOrEqualTo:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName greaterThanValue:(id)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsWithValueGreaterThan:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName greaterThanOrEqualToValue:(id)value
{
    BCOIndex *index = self.indexsByName[indexName];
    return [index recordsWithValueGreaterThanOrEqualTo:value];
}

@end
