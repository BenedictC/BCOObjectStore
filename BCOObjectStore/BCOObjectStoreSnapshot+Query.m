//
//  BCOObjectStoreSnapshot+Query.m
//  Pods
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot+Query.h"
#import "BCOIndex.h"



typedef NS_ENUM(NSInteger, BCOOperator) {
    BCOOperatorInvalid = -1,

    BCOOperatorEqualTo,
    BCOOperatorIn,
    BCOOperatorLessThan,
    BCOOperatorLessThanOrEqualTo,
    BCOOperatorGreaterThan,
    BCOOperatorGreaterThanOrEqualTo,
    BCOOperatorNotEqualTo,
};



@implementation BCOObjectStoreSnapshot (Query)

#define MUST(EXPR, ...) ({if (!(EXPR)) {[NSException raise:NSInvalidArgumentException format:__VA_ARGS__]; return nil; } })
-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable objects:(NSSet *)objects indexes:(NSDictionary *)indexes
{
    NSScanner *scanner = [NSScanner scannerWithString:query];

    //A query must start with 'WHERE'
    MUST([scanner scanString:@"WHERE" intoString:NULL], @"Invalid query. Queries must start with 'WHERE'");

    NSMutableSet *matchingObjects = nil;

    //Scan a clause
    do {
        //TODO: Scan for a `predicate` before scanning for indexName

        NSString *indexName = nil;
        MUST([scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&indexName], @"Expected indexName");

        NSString *operatorString = nil;
        [scanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:&operatorString];
        BCOOperator operator = [self operatorFromString:operatorString];
        MUST(operator != BCOOperatorInvalid, @"Expected operator");

        id value = nil;
        MUST([self scanValueWithScanner:scanner substitutionVariables:subsitutionVariable value:&value], @"Expected value");

        NSSet *objects = [self fetchObjectsFromIndex:indexName operator:operator value:value indexes:indexes];
        BOOL isFirstWhereClause = (matchingObjects == nil);
        if (isFirstWhereClause) {
            matchingObjects = [objects mutableCopy];
        } else {
            [matchingObjects intersectSet:objects];
        }

        //Because we only allow ANDing at the moment the operations will only ever reduce the number of matches
        BOOL isEmpty = objects.count == 0;
        if (isEmpty) return @[];

    } while ([scanner scanString:@"AND" intoString:NULL]); //"Let's go round again"


    return [matchingObjects allObjects];

    //TODO:
    //Scan optional 'ORDERED BY'
    //If NO scan END OF STRING

    //Scan property name

}
#undef MUST



-(BOOL)scanValueWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)substitutionVariables value:(id *)outValue
{
    BOOL didScanVariableDelimiter = [scanner scanString:@"$" intoString:NULL];
    if (didScanVariableDelimiter) {
        NSCharacterSet *variableNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm1234567890_"];
        NSString *variableName = nil;
        BOOL didScanVariableName = [scanner scanUpToCharactersFromSet:variableNameCharacters intoString:&variableName];
        if (!didScanVariableName) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid variable name"];
            return NO;
        }

        id variable = substitutionVariables[variableName];
        if (variableName == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Variable '%@' not found", variableName];
            return NO;
        }
        *outValue = variable;
        return YES;
    }

    double num = 0;
    BOOL didScanNumber = [scanner scanDouble:&num];
    if (didScanNumber) {
        *outValue = @(num);
        return YES;
    }

    BOOL didScanOpeningQuote = [scanner scanString:@"'" intoString:NULL];
    if (didScanOpeningQuote) {
        NSMutableString *value = [NSMutableString new];
        NSString *buffer = nil;

        while ([scanner scanUpToString:@"'" intoString:&buffer]) {
            [value appendString:buffer];

            //If the sting is a 2 single quotes then it is a literal single quote
            BOOL isLiteralQuote = [scanner scanString:@"''" intoString:NULL];
            if (isLiteralQuote) {
                [value appendString:@"'"];
                continue;
            }
            BOOL isClosingQuote = [scanner scanString:@"'" intoString:NULL];
            if (isClosingQuote) {
                *outValue = value;
                return YES;
            }

            [NSException raise:NSInvalidArgumentException format:@"Incorrectly terminated string"];
            return NO;
        }
    }

    BOOL didScanOpenCollectionDelimtter = [scanner scanString:@"{" intoString:NULL];
    if (didScanOpenCollectionDelimtter) {
        NSMutableSet *set = [NSMutableSet new];

        do {
            id value = nil;
            BOOL didScanValue = [self scanValueWithScanner:scanner substitutionVariables:substitutionVariables value:&value];
            if (!didScanValue) {
                [NSException raise:NSInvalidArgumentException format:@"Invalid collection. Expected value."];
                return NO;
            }
            [set addObject:value];
        } while ([scanner scanString:@"," intoString:NULL]);

        BOOL didScanCloseCollectionDelimitter = [scanner scanString:@"}" intoString:NULL];
        if (!didScanCloseCollectionDelimitter) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid collection. Expected '}'"];
            return NO;
        }

        *outValue = set;
        return YES;
    }

    return NO;
}



-(BCOOperator)operatorFromString:(NSString *)string
{
    if ([string isEqualToString:@"="]) return BCOOperatorEqualTo;
    if ([string isEqualToString:@"IN"]) return BCOOperatorIn;
    if ([string isEqualToString:@"<"]) return BCOOperatorLessThan;
    if ([string isEqualToString:@"<="]) return BCOOperatorLessThanOrEqualTo;
    if ([string isEqualToString:@">"]) return BCOOperatorGreaterThan;
    if ([string isEqualToString:@">="]) return BCOOperatorGreaterThanOrEqualTo;
    if ([string isEqualToString:@"!="]) return BCOOperatorNotEqualTo;

    return BCOOperatorInvalid;
}



-(NSSet *)fetchObjectsFromIndex:(NSString *)indexName operator:(BCOOperator)operator value:(id)value indexes:(NSDictionary *)indexes
{
    NSLog(@"'%@' '%@' '%@'", indexName, @(operator), value);

    BCOIndex *indeks = indexes[indexName];

    switch (operator) {
        case BCOOperatorEqualTo: {
            NSSet *keySet = [NSSet setWithObject:value];
            return [self fetchObjectsFromIndex:indeks withKeyInKeySet:keySet];
        }
        case BCOOperatorIn: {
            return [self fetchObjectsFromIndex:indeks withKeyInKeySet:value];
        }

        default:
            break;
    }

    return nil;
}



-(NSSet *)fetchObjectsFromIndex:(BCOIndex *)indeks withKeyInKeySet:(NSSet *)keySet
{
    NSMutableSet *results = [NSMutableSet new];
    
    for (id key in keySet) {
        NSSet *objects = [indeks objectsForKey:key];
        [results unionSet:objects];
    }
    
    return results;
}

@end
