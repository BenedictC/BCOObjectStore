//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"

#import "BCOObjectStorageContainer.h"
#import "BCOStorageRecordsToQueryCatalogEntriesLookUpTable.h"
#import "BCOQueryCatalog.h"
#import "BCOQuery.h"
#import "BCOQueryResultGroup.h"



@interface BCOObjectStoreSnapshot ()
#pragma message "TODO: Improve performance by replacing *some of* the NS* data structures with CF* that do not need to retain/release."
//Storage
@property(nonatomic, readonly) BCOObjectStorageContainer *objectStorage;
//Index
@property(readonly) BCOQueryCatalog *queryCatalog;
//Storage->Index
@property(readonly) BCOStorageRecordsToQueryCatalogEntriesLookUpTable *queryCatalogEntriesByStorageRecords;

//The snap shot assumes ownership of these object so is able to modify them without copying them.
-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog queryCatalogEntriesLookUpTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)lookupTable __attribute__((objc_designated_initializer));
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
+(BCOObjectStoreSnapshot *)snapshotWithPersistentStorePath:(NSString *)path indexDescriptions:(NSDictionary *)indexDescriptions
{
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer objectStorageWithPersistentStorePath:path];

    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:storage indexDescriptions:indexDescriptions];
}



-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(objects);

    //Create storage
    BCOObjectStorageContainer *storage = [BCOObjectStorageContainer new];
    for (id object in objects) {
        [storage addObject:object];
    }

    return [self initWithObjectStorage:storage indexDescriptions:indexDescriptions];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(storage);
    NSParameterAssert(indexDescriptions);

    //Create index
    BCOQueryCatalog *queryCatalog = [[BCOQueryCatalog alloc] initWithIndexDescriptions:indexDescriptions];
    BCOStorageRecordsToQueryCatalogEntriesLookUpTable *queryCatalogEntriesByStorageRecords = [[BCOStorageRecordsToQueryCatalogEntriesLookUpTable alloc] init];

    //Add each object to the queryCatalog
    [storage enumerateStorageRecordsAndObjectsUsingBlock:^(BCOStorageRecord *record, id object, BOOL *stop) {
        BCOQueryCatalogEntry *entry = [queryCatalog addEntryForRecord:record byIndexingObject:object];
        //Store the index entry by storage record
        [queryCatalogEntriesByStorageRecords setQueryCatalogEntry:entry forStorageRecord:record];
    }];

    return [self initWithObjectStorage:storage queryCatalog:queryCatalog queryCatalogEntriesLookUpTable:queryCatalogEntriesByStorageRecords];
}



-(instancetype)initWithObjectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog queryCatalogEntriesLookUpTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)lookupTable
{
    //self assumes ownership of all objects
    self = [super init];
    if (self == nil) return nil;

    _objectStorage = storage;
    _queryCatalog = queryCatalog;
    _queryCatalogEntriesByStorageRecords = lookupTable;

    return self;
}



#pragma mark - properties
-(NSDictionary *)indexDescriptions
{
    return self.queryCatalog.indexDescriptions;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    //We could optimize here by diffing against objects and only update the changes. However the cost of doing that is probably not worth it.
    return [[BCOObjectStoreSnapshot alloc] initWithObjects:newObjects indexDescriptions:self.queryCatalog.indexDescriptions];
}



-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects
{
//TODO: We can optimize here based on the bounds of the sizes. EG. If the new set is so much smaller/bigger than the old set it's easier to start again. Figure out what these conditions are.
    //Copy state
    BCOObjectStorageContainer *newStorage = [self.objectStorage copy];
    BCOQueryCatalog *newQueryCatalog = [self.queryCatalog copy];
    BCOStorageRecordsToQueryCatalogEntriesLookUpTable *newQueryCatalogEntriesByStorageRecords = [self.queryCatalogEntriesByStorageRecords copy];

    //Remove expiredObjects from...
    for (id expiredObject in expiredObjects) {
        //... storage
        BCOStorageRecord *record = [newStorage storageRecordForObject:expiredObject];
        [newStorage removeObjectForStorageRecord:record];
        //...the index by getting the entry
        BCOQueryCatalogEntry *entry = [newQueryCatalogEntriesByStorageRecords queryCatalogEntryForStorageRecord:record];
        [newQueryCatalog removeEntry:entry];
        //... the lookup table
        [newQueryCatalogEntriesByStorageRecords removeQueryCatalogEntryForStorageRecord:record];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        //...storage
        BCOStorageRecord *storageRecord = [newStorage addObject:freshObject];
        //...index
        BCOQueryCatalogEntry *queryCatalogEntry = [newQueryCatalog addEntryForRecord:storageRecord byIndexingObject:freshObject];
        //... the lookUp table
        [newQueryCatalogEntriesByStorageRecords setQueryCatalogEntry:queryCatalogEntry forStorageRecord:storageRecord];
    }

    //Construct the new snapshot
    return [[BCOObjectStoreSnapshot alloc] initWithObjectStorage:newStorage queryCatalog:newQueryCatalog queryCatalogEntriesLookUpTable:newQueryCatalogEntriesByStorageRecords];
}



#pragma mark - BCOObjectStoreSnapshot protocol
-(BOOL)writeToPath:(NSString *)path error:(NSError **)outError
{
    return [self.objectStorage writeToPath:path error:outError];
}



-(id)executeQuery:(NSString *)queryString
{
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:nil];
    return [BCOObjectStoreSnapshot executeQuery:query objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



-(id)executeQuery:(NSString *)queryString substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:subsitutionVariable];
    return [BCOObjectStoreSnapshot executeQuery:query objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



#pragma mark - object access
-(id)executeQueryObject:(BCOQuery *)query
{
    return [BCOObjectStoreSnapshot executeQuery:query objectStorage:self.objectStorage queryCatalog:self.queryCatalog];
}



+(id)executeQuery:(BCOQuery *)query objectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog
{
    //Match the objects (WHERE)
    NSSet *matchedRecords = [self evaluateWHEREClauseExpression:query.rootWhereExpression storage:storage queryCatalog:queryCatalog searchSpace:nil];

    //Convert the records to objects
    NSMutableArray *objects = [NSMutableArray new];
    for (BCOStorageRecord *record in matchedRecords) {
        id object = [storage objectForStorageRecord:record];
        [objects addObject:object];
    }

    //Create ORDERed GROUPs
    return [BCOQueryResultGroup queryResultsWithObjects:objects groupByField:query.groupBy sortDescriptors:query.sortDescriptors selectBlock:query.selectMapper];
}



#pragma mark - Object fetching
+(NSSet *)evaluateWHEREClauseExpression:(BCOWhereClauseExpression *)expression storage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog searchSpace:(NSSet *)searchSpace
{
    switch (expression.operator) {

        case BCOQueryOperatorAND: {
            NSSet *leftSet = [self evaluateWHEREClauseExpression:expression.leftOperand storage:storage queryCatalog:queryCatalog searchSpace:searchSpace];

            //Optimizations
            BOOL isRightBranchRedundant = (leftSet.count == 0);
            if (isRightBranchRedundant)return [NSSet set];
            //TODO: What other optimizations are there?

            //Not that we're restricting the search space to leftSet. Only predicate uses this but that is potential very useful as predicates would otherwise have to scan ALL objects.
            NSSet *rightSet = [self evaluateWHEREClauseExpression:expression.rightOperand storage:storage queryCatalog:queryCatalog searchSpace:leftSet];
            NSMutableSet *intersectSet = [leftSet mutableCopy];
            [intersectSet intersectSet:rightSet];
            return intersectSet;
        }

        case BCOQueryOperatorOR: {
            NSSet *leftSet = [self evaluateWHEREClauseExpression:expression.leftOperand storage:storage queryCatalog:queryCatalog searchSpace:searchSpace];
            NSSet *rightSet = [self evaluateWHEREClauseExpression:expression.rightOperand storage:storage queryCatalog:queryCatalog searchSpace:searchSpace];
            NSMutableSet *unionSet = [leftSet mutableCopy];
            [unionSet unionSet:rightSet];
            return unionSet;
        }

        case BCOQueryOperatorEqualTo: {
            return [queryCatalog recordsInIndex:expression.leftOperand forValue:expression.rightOperand];
        }

        case BCOQueryOperatorNotEqualTo: {
            return [queryCatalog recordsInIndex:expression.leftOperand forValuesNotEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorIn: {
            return [queryCatalog recordsInIndex:expression.leftOperand forValuesInSet:expression.rightOperand];
        }

        case BCOQueryOperatorNotIn: {
            return [queryCatalog recordsInIndex:expression.leftOperand forValuesNotInSet:expression.rightOperand];
        }

        case BCOQueryOperatorLessThan: {
            return [queryCatalog recordsInIndex:expression.leftOperand lessThanValue:expression.rightOperand];
        }

        case BCOQueryOperatorLessThanOrEqualTo: {
            return [queryCatalog recordsInIndex:expression.leftOperand lessThanOrEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorGreaterThan: {
            return [queryCatalog recordsInIndex:expression.leftOperand greaterThanValue:expression.rightOperand];
        }

        case BCOQueryOperatorGreaterThanOrEqualTo: {
            return [queryCatalog recordsInIndex:expression.leftOperand greaterThanOrEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorPredicate: {
            NSPredicate *predicate = expression.leftOperand;
            NSMutableSet *filteredRecords = [NSMutableSet new];
            id recordsToSearch = searchSpace ?: storage.allStorageRecords;
            for (id record in recordsToSearch) {
                id object = [storage objectForStorageRecord:record];
                BOOL didMatch = [predicate evaluateWithObject:object];
                if (didMatch) [filteredRecords addObject:record];
            }
            return filteredRecords;
        }

        case BCOQueryOperatorInvalid: {
            //This should never happen. If it does it indicates a bug in the parsing.
            [NSException raise:NSInvalidArgumentException format:@"Invalid operator."];
            break;
        }
    }
    
    return nil;
}

@end
