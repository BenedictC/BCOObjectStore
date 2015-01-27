//
//  BCOQuery.m
//  Pods
//
//  Created by Benedict Cohen on 25/01/2015.
//
//

#import "BCOQuery.h"



@implementation BCOWhereClauseExpression

-(instancetype)initWithOperator:(BCOQueryOperator)operator indexName:(NSString *)indexName value:(id)value
{
    self = [super init];
    if (self == nil) return nil;

    _operator = operator;
    _indexName = indexName;
    _value = value;

    return self;
}

@end



@implementation BCOQuery

-(instancetype)initWithWhereClauses:(NSArray *)whereClauses sortDescriptors:(NSArray *)sortDescriptors
{
    self = [super init];
    if (self == nil) return nil;

    _whereClauseExpressions = whereClauses;
    _sortDescriptors = sortDescriptors;

    return self;
}



#pragma mark - Query Scanning
+(BCOQuery *)queryFromString:(NSString *)queryString substitutionVariables:(NSDictionary *)subsitutionVariable
{
    NSScanner *scanner = [NSScanner scannerWithString:queryString];

    //A query must start with 'WHERE'
    BOOL didScanWHEREDelimitter = [scanner scanString:@"WHERE" intoString:NULL];
    if (!didScanWHEREDelimitter) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid query. Queries must start with 'WHERE'"];
        return nil;
    }

    //Scan and fetch objcts
    NSMutableArray *whereClauses = [NSMutableArray new];
    do {
        NSPredicate *predicate = [self scanPredicateWithScanner:scanner substitutionVariables:subsitutionVariable];
        if (predicate != nil) {
            BCOWhereClauseExpression *whereClause = [[BCOWhereClauseExpression alloc] initWithOperator:BCOQueryOperatorPredicate indexName:nil value:predicate];
            [whereClauses addObject:whereClause];
            continue;
        }

        NSString *indexName = [self scanIdentifierWithScanner:scanner];
        if (indexName == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Expected index name."];
            return nil;
        }

        BCOQueryOperator operator = [self scanOperatorWithScanner:scanner];
        if (operator == BCOQueryOperatorInvalid) {
            [NSException raise:NSInvalidArgumentException format:@"Expected operator."];
            return nil;
        }

        id value = [self scanValueWithScanner:scanner substitutionVariables:subsitutionVariable];
        if (value == nil) {
            [NSException raise:NSInvalidArgumentException format:@"Expected value."];
            return nil;
        }

        BCOWhereClauseExpression *whereClause = [[BCOWhereClauseExpression alloc] initWithOperator:operator indexName:indexName value:value];
        [whereClauses addObject:whereClause];

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

    return [[BCOQuery alloc] initWithWhereClauses:whereClauses sortDescriptors:sortDescriptors];
}



+(NSPredicate *)scanPredicateWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
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



+(id)scanValueWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)substitutionVariables
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
            return nil;
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



+(id)scanVariableWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)substitutionVariables
{
    BOOL didScanVariableDelimiter = [scanner scanString:@"$" intoString:NULL];
    if (!didScanVariableDelimiter) return nil;

    //Scan the varaible name
    NSString *identifier = [self scanIdentifierWithScanner:scanner];
    if (identifier == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid variable name"];
        return nil;
    }

    //Look up the value
    id variable = substitutionVariables[identifier];
    if (variable == nil) {
        [NSException raise:NSInvalidArgumentException format:@"Variable '%@' not found", identifier];
        return nil;
    }

    return variable;
}



+(NSString *)scanIdentifierWithScanner:(NSScanner *)scanner
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



+(BCOQueryOperator)scanOperatorWithScanner:(NSScanner *)scanner
{
    if ([scanner scanString:@"=" intoString:NULL])  return BCOQueryOperatorEqualTo;
    if ([scanner scanString:@"!=" intoString:NULL]) return BCOQueryOperatorNotEqualTo;

    if ([scanner scanString:@"IN" intoString:NULL]) return BCOQueryOperatorIn;
    if ([scanner scanString:@"in" intoString:NULL]) return BCOQueryOperatorIn;

    //Note that the orde of these scans is significant
    if ([scanner scanString:@"<=" intoString:NULL]) return BCOQueryOperatorLessThanOrEqualTo;
    if ([scanner scanString:@"<" intoString:NULL])  return BCOQueryOperatorLessThan;

    //Note that the orde of these scans is significant
    if ([scanner scanString:@">=" intoString:NULL]) return BCOQueryOperatorGreaterThanOrEqualTo;
    if ([scanner scanString:@">" intoString:NULL])  return BCOQueryOperatorGreaterThan;
    
    return BCOQueryOperatorInvalid;
}

@end
