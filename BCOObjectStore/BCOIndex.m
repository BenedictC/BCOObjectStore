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
-(instancetype)initWithColumnDescriptions:(NSDictionary *)columnDescriptions
{
    //Create and add the index
    NSMutableDictionary *mutableIndexesByName = [NSMutableDictionary new];
    [columnDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOColumnDescription *columnDescription, BOOL *stop) {
        BCOColumn *newColumn = [[BCOColumn alloc] initWithColumnDescription:columnDescription];
        mutableIndexesByName[indexName] = newColumn;
    }];

    return [self initWithColumnDescriptions:columnDescriptions mutableColumnsByName:mutableIndexesByName];
}



-(instancetype)initWithColumnDescriptions:(NSDictionary *)columnDescriptions mutableColumnsByName:(NSMutableDictionary *)mutableColumnsByName
{
    NSParameterAssert(columnDescriptions);
    NSParameterAssert(mutableColumnsByName);

    self = [super init];
    if (self == nil) return nil;

    _columnDescriptions = [columnDescriptions copy];
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

    return [[BCOIndex alloc] initWithColumnDescriptions:self.columnDescriptions mutableColumnsByName:mutableColumnsByName];
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
        id value = [column generateColumnValueForObject:object];
        if (value == nil) return;

        //Add the record to the column
        [column addRecord:record forColumnValue:value];

        //Add a reference for the columnName:value pair to the entry.
        entry.valuesByColumnName[columnName] = value;
    }];

    return entry;
}



-(void)removeEntry:(BCOIndexEntry *)indexEntry
{
    NSDictionary *mutableColumns = self.mutableColumnsByName;
    [indexEntry.valuesByColumnName enumerateKeysAndObjectsUsingBlock:^(NSString *columnName, id value, BOOL *stop) {
        BCOColumn *column = mutableColumns[columnName];
        [column removeRecord:indexEntry.record forColumnValue:value];
    }];
}



-(void)enumerateKeysAndObjectsUsingBlock:(void(^)(NSString *indexName, BCOColumn *index, BOOL *stop))block
{
    [self.mutableColumnsByName enumerateKeysAndObjectsUsingBlock:block];
}



#pragma mark - modifying
-(NSSet *)recordsInColumn:(NSString *)columnName forValue:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsForValue:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName forValuesInSet:(NSSet *)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsForValuesInSet:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName lessThanValue:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsWithValueLessThan:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName lessThanOrEqualToValue:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsWithValueLessThanOrEqualTo:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanValue:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsWithValueGreaterThan:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanOrEqualToValue:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsWithValueGreaterThanOrEqualTo:value];
}



-(NSSet *)recordsInColumn:(NSString *)columnName forKeysNotEqualToValue:(id)value
{
    BCOColumn *column = self.columnsByName[columnName];
    return [column recordsWithValueNotEqualTo:value];
}

@end
