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

    //Get the matching records
    NSSet *matchedRecords = [self evaluateWHEREClauseExpression:query.rootWhereExpression storage:storage index:index];

    //Convert the records to objects
    NSMutableArray *objects = [NSMutableArray new];
    for (BCOStorageRecord *record in matchedRecords) {
        id object = [storage objectForStorageRecord:record];
        [objects addObject:object];
    }

    //Sort the objects
    return [objects sortedArrayUsingDescriptors:query.sortDescriptors];
}



#pragma mark - Object fetching
-(NSSet *)evaluateWHEREClauseExpression:(BCOWhereClauseExpression *)expression storage:(BCOObjectStorageContainer *)storage index:(BCOIndex *)index
{
    switch (expression.operator) {

        case BCOQueryOperatorAND: {
            NSSet *leftSet = [self evaluateWHEREClauseExpression:expression.leftOperand storage:storage index:index];
            NSSet *rightSet = [self evaluateWHEREClauseExpression:expression.rightOperand storage:storage index:index];
            NSMutableSet *intersectSet = [leftSet mutableCopy];
            [intersectSet intersectSet:rightSet];
            return intersectSet;
        }

        case BCOQueryOperatorOR: {
            NSSet *leftSet = [self evaluateWHEREClauseExpression:expression.leftOperand storage:storage index:index];
            NSSet *rightSet = [self evaluateWHEREClauseExpression:expression.rightOperand storage:storage index:index];
            NSMutableSet *unionSet = [leftSet mutableCopy];
            [unionSet unionSet:rightSet];
            return unionSet;
        }

        case BCOQueryOperatorEqualTo: {
            return [index recordsInColumn:expression.leftOperand forValue:expression.rightOperand];
        }

        case BCOQueryOperatorIn: {
            return [index recordsInColumn:expression.leftOperand forValuesInSet:expression.rightOperand];
        }

        case BCOQueryOperatorLessThan: {
            return [index recordsInColumn:expression.leftOperand lessThanValue:expression.rightOperand];
        }

        case BCOQueryOperatorLessThanOrEqualTo: {
            return [index recordsInColumn:expression.leftOperand lessThanOrEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorGreaterThan: {
            return [index recordsInColumn:expression.leftOperand greaterThanValue:expression.rightOperand];
        }

        case BCOQueryOperatorGreaterThanOrEqualTo: {
            return [index recordsInColumn:expression.leftOperand greaterThanOrEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorNotEqualTo: {
            return [index recordsInColumn:expression.leftOperand forKeysNotEqualToValue:expression.rightOperand];
        }

        case BCOQueryOperatorPredicate:
        {
            NSPredicate *predicate = expression.leftOperand;
            NSMutableSet *filteredRecords = [NSMutableSet new];
            for (id record in storage.allStorageRecords) {
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
