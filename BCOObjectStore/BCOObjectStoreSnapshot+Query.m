//
//  BCOObjectStoreSnapshot+Query.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot+Query.h"
#import "BCOColumn.h"
#import "BCOQuery.h"
#import "BCOObjectStorageContainer.h"
#import "BCOIndex.h"



@implementation BCOObjectStoreSnapshot (Query)

-(NSArray *)executeQuery:(NSString *)queryString subsitutionVariable:(NSDictionary *)subsitutionVariable objectStorage:(BCOObjectStorageContainer *)storage index:(BCOIndex *)index
{
    //Create the query
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:subsitutionVariable];

    //Filter
    NSMutableSet *allMatchedRecords = nil;
    for (BCOWhereClauseExpression *expression in query.whereClauseExpressions) {

        //Fetch the objects for the individual WHERE clause
        NSSet *potentialRecords = allMatchedRecords ?: [NSSet setWithArray:storage.allStorageRecords];
        NSSet *matchedRecords = [self evaluateWHEREClauseExpression:expression tokens:potentialRecords storage:storage index:index];

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
-(NSSet *)evaluateWHEREClauseExpression:(BCOWhereClauseExpression *)expression tokens:(NSSet *)records storage:(BCOObjectStorageContainer *)storage index:(BCOIndex *)index
{
    switch (expression.operator) {

        case BCOQueryOperatorEqualTo: {
            return [index recordsInColumn:expression.indexName forKey:expression.value];
        }

        case BCOQueryOperatorIn: {
            return [index recordsInColumn:expression.indexName forKeysInSet:expression.value];
        }

        case BCOQueryOperatorLessThan: {
            return [index recordsInColumn:expression.indexName lessThanKey:expression.value];
        }

        case BCOQueryOperatorLessThanOrEqualTo: {
            return [index recordsInColumn:expression.indexName lessThanOrEqualToKey:expression.value];
        }

        case BCOQueryOperatorGreaterThan: {
            return [index recordsInColumn:expression.indexName greaterThanKey:expression.value];
        }

        case BCOQueryOperatorGreaterThanOrEqualTo: {
            return [index recordsInColumn:expression.indexName greaterThanOrEqualToKey:expression.value];
        }

        case BCOQueryOperatorNotEqualTo: {
            return [index recordsInColumn:expression.indexName forKeysNotEqualToKey:expression.value];
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
