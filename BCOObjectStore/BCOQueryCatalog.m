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

@property(nonatomic, readonly) NSDictionary *indexesByName;

@end



@implementation BCOQueryCatalog

#pragma mark - instance life cycle
-(instancetype)initWithIndexesByName:(NSDictionary *)indexesByName
{
    NSParameterAssert(indexesByName);

    self = [super init];
    if (self == nil) return nil;

    _indexesByName = indexesByName;

    return self;
}



#pragma mark - properties
-(NSDictionary *)indexDescriptions
{
    NSMutableDictionary *descriptions = [NSMutableDictionary new];
    [self.indexesByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        descriptions[indexName] = index.indexDescription;
    }];

    return descriptions;
}



#pragma mark - access
-(NSSet *)recordsInIndex:(NSString *)indexName forValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsForValue:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName forValuesNotEqualToValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsWithValueNotEqualTo:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName forValuesInSet:(NSArray *)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsForValuesInSet:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName forValuesNotInSet:(NSArray *)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsForValuesNotInSet:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName lessThanValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsWithValueLessThan:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName lessThanOrEqualToValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsWithValueLessThanOrEqualTo:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName greaterThanValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsWithValueGreaterThan:value];
}



-(NSSet *)recordsInIndex:(NSString *)indexName greaterThanOrEqualToValue:(id)value
{
    BCOIndex *index = self.indexesByName[indexName];
    return [index recordsWithValueGreaterThanOrEqualTo:value];
}

@end



@interface BCOQueryCatalogBuilder ()
@property(nonatomic, readonly) NSDictionary *indexBuildersByIndexName;
@end



@implementation BCOQueryCatalogBuilder

+(instancetype)builderWithIndexDescriptions:(NSDictionary *)indexDescriptions
{
    NSMutableDictionary *indexBuildersByIndexName = [NSMutableDictionary new];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        indexBuildersByIndexName[indexName] = [BCOIndexBuilder builderWithIndexDescription:indexDescription];
    }];

    return [[BCOQueryCatalogBuilder alloc] initWithIndexBuildersByIndexName:indexBuildersByIndexName];
}



+(instancetype)builderWithPreviousQueryCatalog:(BCOQueryCatalog *)queryCatalog
{
    NSMutableDictionary *indexBuildersByIndexName = [NSMutableDictionary new];
    [queryCatalog.indexesByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndex *index, BOOL *stop) {
        indexBuildersByIndexName[indexName] = [BCOIndexBuilder builderWithPreviousIndex:index];
    }];

    return [[BCOQueryCatalogBuilder alloc] initWithIndexBuildersByIndexName:indexBuildersByIndexName];
}



-(instancetype)initWithIndexBuildersByIndexName:(NSDictionary *)indexBuildersByIndexName
{
    NSParameterAssert(indexBuildersByIndexName);
    if (self == nil) return nil;

    _indexBuildersByIndexName = indexBuildersByIndexName;

    return self;
}



#pragma mark - access
-(BCOQueryCatalogEntry *)addEntryForRecord:(id)record byIndexingObject:(id)object
{
    //Keep track of which values are added to which index
    NSMutableDictionary *indexValuesByIndexName = [NSMutableDictionary new];

    [self.indexBuildersByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexBuilder *builder, BOOL *stop) {
        id value = [builder generateIndexValueForObject:object];
        if (value == nil) return;

        //Add the record to the index
        [builder addRecord:record forIndexValue:value];

        //Add a reference for the indexName:value pair to the entry.
        indexValuesByIndexName[indexName] = value;
    }];

    BCOQueryCatalogEntry *entry = [[BCOQueryCatalogEntry alloc] initWithRecord:record indexValuesByIndexName:indexValuesByIndexName];

    return entry;
}



-(void)removeEntry:(BCOQueryCatalogEntry *)queryCatalogEntry
{
    NSDictionary *builders = self.indexBuildersByIndexName;
    [queryCatalogEntry.indexValuesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, id value, BOOL *stop) {
        BCOIndexBuilder *builder = builders[indexName];
        [builder removeRecord:queryCatalogEntry.record forIndexValue:value];
    }];
}



-(BCOQueryCatalog *)finalize
{
    NSAssert(_indexBuildersByIndexName != nil, @"");

    NSMutableDictionary *indexesByName = [NSMutableDictionary new];
    [self.indexBuildersByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexBuilder *builder, BOOL *stop) {
        indexesByName[indexName] = builder.finalize;
    }];

    _indexBuildersByIndexName = nil;

    return [[BCOQueryCatalog alloc] initWithIndexesByName:indexesByName];
}

@end