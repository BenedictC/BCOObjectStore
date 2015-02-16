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

@property(nonatomic, readonly) NSMutableDictionary *mutableIndexesByName;

@end



@implementation BCOQueryCatalog

#pragma mark - instance life cycle
-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions
{
    //Create and add the index
    NSMutableDictionary *mutableIndexesByName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        BCOIndex *newIndex = [[BCOIndex alloc] initWithIndexDescription:indexDescription];
        mutableIndexesByName[indexName] = newIndex;
    }];

    return [self initWithIndexDescriptions:indexDescriptions mutableIndexesByName:mutableIndexesByName];
}



-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions mutableIndexesByName:(NSMutableDictionary *)mutableIndexesByName
{
    NSParameterAssert(indexDescriptions);
    NSParameterAssert(mutableIndexesByName);

    self = [super init];
    if (self == nil) return nil;

    _indexDescriptions = [indexDescriptions copy];
    _mutableIndexesByName = mutableIndexesByName;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    //Perfrom a deep copy of the indexes
    NSMutableDictionary *mutableIndexesByName = [NSMutableDictionary new];
    [self.mutableIndexesByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        mutableIndexesByName[indexName] = [index copy];
    }];

    return [[BCOQueryCatalog alloc] initWithIndexDescriptions:self.indexDescriptions mutableIndexesByName:mutableIndexesByName];
}



#pragma mark - properties
-(NSDictionary *)indexesByName
{
    return _mutableIndexesByName;
}



#pragma mark - access
-(BCOQueryCatalogEntry *)addEntryForReference:(id)reference byIndexingObject:(id)object
{
    NSMutableDictionary *indexValuesByIndexName = [NSMutableDictionary new];

    [self.indexesByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        id value = [index generateIndexValueForObject:object];
        if (value == nil) return;

        //Add the reference to the index
        [index addReference:reference forIndexValue:value];

        //Add a reference for the indexName:value pair to the entry.
        indexValuesByIndexName[indexName] = value;
    }];

    BCOQueryCatalogEntry *entry = [[BCOQueryCatalogEntry alloc] initWithReference:reference indexValuesByIndexName:indexValuesByIndexName];

    return entry;
}



-(void)removeEntry:(BCOQueryCatalogEntry *)queryCatalogEntry
{
    NSDictionary *mutableIndexes = self.mutableIndexesByName;
    [queryCatalogEntry.indexValuesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, id value, BOOL *stop) {
        BCOIndex *index = mutableIndexes[indexName];
        [index removeReference:queryCatalogEntry.reference forIndexValue:value];
    }];
}



-(void)enumerateKeysAndObjectsUsingBlock:(void(^)(NSString *indexName, BCOIndex *index, BOOL *stop))block
{
    [self.mutableIndexesByName enumerateKeysAndObjectsUsingBlock:block];
}



#pragma mark - modifying
-(NSSet *)referencesInIndex:(NSString *)indexName forValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesForValue:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName forValuesNotEqualToValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesWithValueNotEqualTo:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName forValuesInSet:(NSArray *)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesForValuesInSet:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName forValuesNotInSet:(NSArray *)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesForValuesNotInSet:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName lessThanValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesWithValueLessThan:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName lessThanOrEqualToValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesWithValueLessThanOrEqualTo:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName greaterThanValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesWithValueGreaterThan:value];
}



-(NSSet *)referencesInIndex:(NSString *)indexName greaterThanOrEqualToValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index referencesWithValueGreaterThanOrEqualTo:value];
}

@end
