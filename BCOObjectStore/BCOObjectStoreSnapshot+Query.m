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

-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable objects:(NSSet *)objects indexes:(NSDictionary *)indexes
{
    NSScanner *scanner = [NSScanner scannerWithString:query];

    //A query must start with 'WHERE'
    BOOL didScanWHEREDelimitter = [scanner scanString:@"WHERE" intoString:NULL];
    if (!didScanWHEREDelimitter) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid query. Queries must start with 'WHERE'"];
        return nil;
    }

    //Scan and fetch objcts
    NSMutableSet *matchingObjects = nil;
    do {
        NSPredicate *predicate = [self scanPredicateWithScanner:scanner substitutionVariables:subsitutionVariable];
        if (predicate != nil) {
            NSSet *objectsToFilter = (matchingObjects == nil) ? self.objects : matchingObjects;
            NSSet *filteredObjects = [objectsToFilter filteredSetUsingPredicate:predicate];

            BOOL isFirstWhereClause = matchingObjects == nil;
            if (isFirstWhereClause) {
                matchingObjects = [filteredObjects mutableCopy];
            } else {
                [matchingObjects intersectSet:filteredObjects];
            }
            continue;
        }

        NSString *indexName = [self scanIdentifierWithScanner:scanner];
        if (indexName == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Expected index name."];
            return nil;
        }

        BCOOperator operator = [self scanOperatorWithScanner:scanner];
        if (operator == BCOOperatorInvalid) {
            [NSException raise:NSInvalidArgumentException format:@"Expected operator."];
            return nil;
        }

        id value = [self scanValueWithScanner:scanner substitutionVariables:subsitutionVariable];
        if (value == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Expected value."];
            return nil;
        }

        //Get the matches
        BOOL isFirstWhereClause = (matchingObjects == nil);
        if (isFirstWhereClause) {
            NSSet *objects = [self fetchObjectsFromIndex:indexName operator:operator value:value indexes:indexes];
            matchingObjects = [objects mutableCopy];
            continue;
        }

        //Because we currently only allow ANDing the operations will only ever reduce the number of matches so we can bail early
        //(We could return now, but we don't so that the query is completely parsed thus finding any errors in in.)
        BOOL isEmpty = objects.count == 0;
        if (isEmpty) continue;

        //Narrow the results
        [matchingObjects intersectSet:objects];

    } while ([scanner scanString:@"AND" intoString:NULL]); //"Let's go round again"


    //Scan optional 'ORDERED BY'
    NSMutableArray *sortDescriptors = [NSMutableArray new];
    BOOL didScanORDEREDBYDelimitter = [scanner scanString:@"ORDERED BY" intoString:NULL];
    if (didScanORDEREDBYDelimitter) {
        do {
            //Attempt to scan a sort descriptor variable
            id sortDescriptor = [self scanVariableWithScanner:scanner substitutionVariables:subsitutionVariable];
            if ([sortDescriptor isKindOfClass:NSSortDescriptor.class]) {
                [sortDescriptors addObject:sortDescriptor];
                continue;
            } else  if (sortDescriptor != nil) {
                //sortDescriptor is not of the expected class
                [NSException raise:NSInvalidArgumentException format:@"Expected NSSortDescriptor for varible."];
                return nil;
            }

            //else scan a property name...
            NSString *key = [self scanIdentifierWithScanner:scanner];
            if (key == nil) {
                [NSException raise:NSInvalidArgumentException format:@"Expected sort key."];
                return nil;
            }
            //...followed by an optional sort direction
            BOOL ascending = YES;
            if ([scanner scanString:@"DESC" intoString:NULL]) {
                ascending = NO;
            } else {
                //Consume a  trailing ASC. We don't need to set it because the default is YES
                [scanner scanString:@"ASC" intoString:NULL];
            }
            //...and create a sort descriptor
            [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];

        } while ([scanner scanString:@"," intoString:NULL]);
    }

    //Check that there's no junk at the end of the query
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    if (!scanner.isAtEnd) {
        [NSException raise:NSInvalidArgumentException format:@"Junk found at end of query."];
        return nil;
    }

    //Sort and go!
    NSArray *sortedObjects = [matchingObjects sortedArrayUsingDescriptors:sortDescriptors];
    return sortedObjects;
}



-(NSPredicate *)scanPredicateWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BOOL didScanPredicateOpeningDelimitter = [scanner scanString:@"`" intoString:NULL];
    if (!didScanPredicateOpeningDelimitter) return nil;

    NSString *predicateFormat = nil;
    BOOL didScanPredicate = [scanner scanUpToString:@"`" intoString:&predicateFormat];
    if (!didScanPredicate) {
        [NSException raise:NSInvalidArgumentException format:@"Expected predicate string."];
        return nil;
    }

    BOOL didScanPredicateClosingDelimitter = [scanner scanString:@"`" intoString:nil];
    if (!didScanPredicateClosingDelimitter) {
        [NSException raise:NSInvalidArgumentException format:@"Expected end of predicate."];
        return nil;
    }

    return [[NSPredicate predicateWithFormat:predicateFormat] predicateWithSubstitutionVariables:subsitutionVariable];
}



-(id)scanValueWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)substitutionVariables
{
    //Variable
    id variable = [self scanVariableWithScanner:scanner substitutionVariables:substitutionVariables];
    if (variable != nil) {
        return variable;
    }

    //Number
    double num = 0;
    BOOL didScanNumber = [scanner scanDouble:&num];
    if (didScanNumber) {
        return @(num);
    }

    //String
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
                return value;
            }

            [NSException raise:NSInvalidArgumentException format:@"Incorrectly terminated string"];
            return NO;
        }
    }

    //Collection
    BOOL didScanOpenCollectionDelimtter = [scanner scanString:@"{" intoString:NULL];
    if (didScanOpenCollectionDelimtter) {
        NSMutableSet *set = [NSMutableSet new];

        do {
            id value = [self scanValueWithScanner:scanner substitutionVariables:substitutionVariables];
            if (value == nil) {
                [NSException raise:NSInvalidArgumentException format:@"Invalid collection. Expected value."];
                return nil;
            }
            [set addObject:value];
        } while ([scanner scanString:@"," intoString:NULL]);

        BOOL didScanCloseCollectionDelimitter = [scanner scanString:@"}" intoString:NULL];
        if (!didScanCloseCollectionDelimitter) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid collection. Expected '}'"];
            return nil;
        }

        return set;
    }

    return nil;
}



-(id)scanVariableWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)substitutionVariables
{
    BOOL didScanVariableDelimiter = [scanner scanString:@"$" intoString:NULL];
    if (!didScanVariableDelimiter) return nil;

    //Scan the varaible name
    NSString *identifier = [self scanIdentifierWithScanner:scanner];
    if (identifier == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid variable name"];
        return NO;
    }

    //Look up the value
    id variable = substitutionVariables[identifier];
    if (variable == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Variable '%@' not found", identifier];
        return NO;
    }

    return variable;
}



-(NSString *)scanIdentifierWithScanner:(NSScanner *)scanner
{
    static NSCharacterSet *variableNameCharacters = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        variableNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm1234567890_"];
    });

    NSString *variableName = nil;
    [scanner scanCharactersFromSet:variableNameCharacters intoString:&variableName];

    return variableName;
}



-(BCOOperator)scanOperatorWithScanner:(NSScanner *)scanner
{
    if ([scanner scanString:@"=" intoString:NULL])  return BCOOperatorEqualTo;
    if ([scanner scanString:@"!=" intoString:NULL]) return BCOOperatorNotEqualTo;

    if ([scanner scanString:@"IN" intoString:NULL]) return BCOOperatorIn;
    if ([scanner scanString:@"in" intoString:NULL]) return BCOOperatorIn;

    //Note that the orde of these scans is significant
    if ([scanner scanString:@"<=" intoString:NULL]) return BCOOperatorLessThanOrEqualTo;
    if ([scanner scanString:@"<" intoString:NULL])  return BCOOperatorLessThan;

    //Note that the orde of these scans is significant
    if ([scanner scanString:@">=" intoString:NULL]) return BCOOperatorGreaterThanOrEqualTo;
    if ([scanner scanString:@">" intoString:NULL])  return BCOOperatorGreaterThan;

    return BCOOperatorInvalid;
}



-(NSSet *)fetchObjectsFromIndex:(NSString *)indexName operator:(BCOOperator)operator value:(id)value indexes:(NSDictionary *)indexes
{
    BCOIndex *index = indexes[indexName];

    switch (operator) {
        case BCOOperatorEqualTo:
            return [index objectsForKey:value];
        case BCOOperatorIn:
            return [index objectsForKeysInSet:value];
        case BCOOperatorLessThan:
            return [index objectsLessThanKey:value];
        case BCOOperatorLessThanOrEqualTo:
            return [index objectsLessThanOrEqualToKey:value];
        case BCOOperatorGreaterThan:
            return [index objectsGreaterThanKey:value];
        case BCOOperatorGreaterThanOrEqualTo:
            return [index objectsGreaterThanOrEqualToKey:value];
        case BCOOperatorNotEqualTo:
            return [index objectsForKeysNotEqualToKey:value];
        case BCOOperatorInvalid:
            break;
    }

    return nil;
}

@end
