//
//  BCOObjectStoreSnapshot+Query.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot+Query.h"
#import "BCOIndex.h"
#import "BCOQuery.h"
#import "BCOInMemoryObjectStorage.h"



@implementation BCOObjectStoreSnapshot (Query)

-(NSArray *)executeQuery:(NSString *)queryString subsitutionVariable:(NSDictionary *)subsitutionVariable objectStorage:(BCOInMemoryObjectStorage *)storage indexes:(NSDictionary *)indexes
{
    //Create the query
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:subsitutionVariable];

    //Filter
    NSMutableSet *allMatchedRecords = nil;
    for (BCOWhereClauseExpression *expression in query.whereClauseExpressions) {

        //Fetch the objects for the individual WHERE clause
        NSSet *potentialRecords = (allMatchedRecords == nil) ? [NSSet setWithArray:storage.allStorageRecords] : allMatchedRecords;
        NSSet *matchedRecords = [self evaluateWHEREClauseExpression:expression tokens:potentialRecords storage:storage indexes:indexes];

        //Intersect with the existing objects
        if (allMatchedRecords == nil) {
            allMatchedRecords = [matchedRecords mutableCopy];
        } else {
            [allMatchedRecords intersectSet:matchedRecords];
        }

        //Because we only allow ANDing of WHERE clauses we can bail as soon as there are 0 matches.
        if (allMatchedRecords.count == 0) {
            return @[];
        }
    }

    //Convert records to objects
    NSMutableArray *objects = [NSMutableArray new];
    for (BCOStorageRecord *record in allMatchedRecords) {
        id object = [storage objectForStorageRecord:record];
        [objects addObject:object];
    }

    //Sort
    return [objects sortedArrayUsingDescriptors:query.sortDescriptors];
}



#pragma mark - Object fetching
-(NSSet *)evaluateWHEREClauseExpression:(BCOWhereClauseExpression *)expression tokens:(NSSet *)records storage:(BCOInMemoryObjectStorage *)storage indexes:(NSDictionary *)indexes
{
    switch (expression.operator) {

        case BCOQueryOperatorEqualTo: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsForKey:expression.value];
        }

        case BCOQueryOperatorIn: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsForKeysInSet:expression.value];
        }

        case BCOQueryOperatorLessThan: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsLessThanKey:expression.value];
        }

        case BCOQueryOperatorLessThanOrEqualTo: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsLessThanOrEqualToKey:expression.value];
        }

        case BCOQueryOperatorGreaterThan: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsGreaterThanKey:expression.value];
        }

        case BCOQueryOperatorGreaterThanOrEqualTo: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsGreaterThanOrEqualToKey:expression.value];
        }

        case BCOQueryOperatorNotEqualTo: {
            BCOIndex *index = indexes[expression.indexName];
            return [index objectsForKeysNotEqualToKey:expression.value];
        }

        case BCOQueryOperatorPredicate:
        {
            NSPredicate *predicate = expression.value;
            NSMutableSet *filteredObjects = [NSMutableSet new];
            for (BCOStorageRecord *record in records) {
                id object = [storage objectForStorageRecord:record];
                BOOL didMatch = [predicate evaluateWithObject:object];
                if (didMatch) [filteredObjects addObject:record];
            }
            return filteredObjects;
        }

        case BCOQueryOperatorInvalid: {
            [NSException raise:NSInvalidArgumentException format:@"Invalid operator for index."];
            break;
        }
    }

    return nil;
}



@end
