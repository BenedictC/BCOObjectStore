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



@implementation BCOObjectStoreSnapshot (Query)

-(NSArray *)executeQuery:(NSString *)queryString subsitutionVariable:(NSDictionary *)subsitutionVariable objects:(NSSet *)allObjects indexes:(NSDictionary *)indexes
{
    //Create the query
    BCOQuery *query = [BCOQuery queryFromString:queryString substitutionVariables:subsitutionVariable];

    //Filter
    NSMutableSet *allMatchedObjects = nil;
    for (BCOWhereClauseExpression *expression in query.whereClauseExpressions) {

        //Fetch the objects for the individual WHERE clause
        NSSet *objects = (allMatchedObjects == nil) ? allObjects : allMatchedObjects;
        NSSet *matchedObjects = [self evaluateWHEREClauseExpression:expression objects:objects indexes:indexes];

        //Intersect with the existing objects
        if (allMatchedObjects == nil) {
            allMatchedObjects = [matchedObjects mutableCopy];
        } else {
            [allMatchedObjects intersectSet:matchedObjects];
        }

        //Because we only allow ANDing of WHERE clauses we can bail as soon as there are 0 matches.
        if (allMatchedObjects.count == 0) {
            return @[];
        }
    }

    //Sort
    return [allMatchedObjects sortedArrayUsingDescriptors:query.sortDescriptors];
}



#pragma mark - Object fetching
-(NSSet *)evaluateWHEREClauseExpression:(BCOWhereClauseExpression *)expression objects:(NSSet *)objects indexes:(NSDictionary *)indexes
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
            for (id object in objects) {
                BOOL didMatch = [predicate evaluateWithObject:object];
                if (didMatch) [filteredObjects addObject:object];
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
