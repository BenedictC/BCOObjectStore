//
//  BCOIndex.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 29/01/2015.
//
//

#import "BCOIndex.h"
#import "BCOColumn.h"



@interface BCOIndex ()

@property(nonatomic, readonly) NSMutableDictionary *mutableColumnsByName;

@end



@implementation BCOIndex

#pragma mark - instance life cycle
-(instancetype)initWithIndexColumnDescriptions:(NSDictionary *)indexColumnDescriptions
{
    //Create and add the index
    NSMutableDictionary *mutableIndexesByName = [NSMutableDictionary new];
    [indexColumnDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexColumnDescription *indexColumnDescription, BOOL *stop) {
        BCOColumn *newIndex = [[BCOColumn alloc] initWithIndexColumnDescription:indexColumnDescription];
        mutableIndexesByName[indexName] = newIndex;
    }];

    return [self initWithIndexColumnDescriptions:indexColumnDescriptions mutableColumnsByName:mutableIndexesByName];
}



-(instancetype)initWithIndexColumnDescriptions:(NSDictionary *)indexColumnDescriptions mutableColumnsByName:(NSMutableDictionary *)mutableColumnsByName
{
    NSParameterAssert(indexColumnDescriptions);
    NSParameterAssert(mutableColumnsByName);

    self = [super init];
    if (self == nil) return nil;

    _indexColumnDescriptions = [indexColumnDescriptions copy];
    _mutableColumnsByName = mutableColumnsByName;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    //Perfrom a deep copy of the indexes
    NSMutableDictionary *mutableColumnsByName = [NSMutableDictionary new];
    [self.mutableColumnsByName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOColumn *index, BOOL *stop) {
        mutableColumnsByName[indexName] = [index copy];
    }];

    return [[BCOIndex alloc] initWithIndexColumnDescriptions:self.indexColumnDescriptions mutableColumnsByName:mutableColumnsByName];
}



#pragma mark - properties
-(NSDictionary *)columnsByName
{
    return _mutableColumnsByName;
}



#pragma mark - access
-(BCOIndexEntry *)insertEntryForRecord:(id)record byIndexingObject:(id)object
{
    BCOIndexEntry *entry = [[BCOIndexEntry alloc] initWithRecord:record];
    [self.columnsByName enumerateKeysAndObjectsUsingBlock:^(NSString *columnName, BCOColumn *column, BOOL *stop) {
        id key = [column generateColumnKeyForObject:object];
        if (key == nil) return;

        //Add the record to the column
        [column addRecord:record forKey:key];

        //Add a reference for the columnName:key pair to the entry.
        entry.keysByColumnName[columnName] = key;
    }];

    return entry;
}



-(void)removeEntry:(BCOIndexEntry *)indexEntry
{
    NSDictionary *mutableColumns = self.mutableColumnsByName;
    [indexEntry.keysByColumnName enumerateKeysAndObjectsUsingBlock:^(NSString *columnName, id key, BOOL *stop) {
        BCOColumn *column = mutableColumns[columnName];
        [column removeRecord:indexEntry.record forKey:key];
    }];
}



-(id)objectForKeyedSubscript:(NSString *)key
{
    return self.mutableColumnsByName[key];
}



-(void)enumerateKeysAndObjectsUsingBlock:(void(^)(NSString *indexName, BCOColumn *index, BOOL *stop))block
{
    [self.mutableColumnsByName enumerateKeysAndObjectsUsingBlock:block];
}



#pragma mark - modifying
-(NSSet *)recordsInColumn:(NSString *)columnName forKey:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsForKey:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName forKeysInSet:(NSSet *)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsForKeysInSet:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName lessThanKey:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsLessThanKey:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName lessThanOrEqualToKey:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsLessThanOrEqualToKey:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanKey:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsGreaterThanKey:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanOrEqualToKey:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsGreaterThanOrEqualToKey:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName forKeysNotEqualToKey:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsForKeysNotEqualToKey:value];
}

@end
