//
//  BCOQuery.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 25/01/2015.
//
//

#import "BCOQuery.h"



static inline BOOL isObjectABlock(id variable) {
    static Class blockClass = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [^{} class];
        while (![[class superclass] isEqual:NSObject.class]) {
            class = [class superclass];
        }
        blockClass = class;
    });

    return [variable isKindOfClass:blockClass];
}



@implementation BCOWhereClauseExpression

-(instancetype)initWithOperator:(BCOQueryOperator)operator leftOperand:(id)leftOperand rightOperand:(id)rightOperand
{
    self = [super init];
    if (self == nil) return nil;

    _operator = operator;
    _leftOperand = leftOperand;
    _rightOperand = rightOperand;

    return self;
}

@end



@implementation BCOQuery

-(instancetype)initWithSelectFunction:(id (^)(NSArray *))selectFunction rootWhereClauseExpression:(BCOWhereClauseExpression *)rootWhereExpression groupBy:(NSString *)groupBy sortDescriptors:(NSArray *)sortDescriptors
{
    self = [super init];
    if (self == nil) return nil;

    _selectFunction = selectFunction;
    _rootWhereExpression = rootWhereExpression;
    _groupBy = [groupBy copy];
    _sortDescriptors = sortDescriptors;

    return self;
}



#pragma mark - Query Scanning
+(BCOQuery *)queryFromString:(NSString *)queryString substitutionVariables:(NSDictionary *)subsitutionVariable predefinedSelectFunctions:(NSDictionary *)selectFunctions
{
    NSScanner *scanner = [NSScanner scannerWithString:queryString];

    id (^selectFunction)(NSArray *) = [self scanSelectClauseWithScanner:scanner substitutionVariables:subsitutionVariable predefinedSelectFunctions:selectFunctions];
    BCOWhereClauseExpression *where = [self scanWhereClauseWithScanner:scanner substitutionVariables:subsitutionVariable];
    NSString *groupBy = [self scanGroupByClauseWithScanner:scanner substitutionVariables:subsitutionVariable];
    NSArray *sortDescriptors = [self scanOrderByClauseWithScanner:scanner substitutionVariables:subsitutionVariable];

    //Check that there's no junk at the end of the query
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];
    if (!scanner.isAtEnd) {
        [NSException raise:NSInvalidArgumentException format:@"Junk found at end of query."];
        return nil;
    }

    return [[BCOQuery alloc] initWithSelectFunction:selectFunction rootWhereClauseExpression:where groupBy:groupBy sortDescriptors:sortDescriptors];
}



#pragma mark - SELECT
+(id(^)(NSArray *))scanSelectClauseWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable predefinedSelectFunctions:(NSDictionary *)functions
{
    BOOL didScanSELECT = [scanner scanString:@"SELECT" intoString:NULL];

    //Default to selecting whole objects
    if (!didScanSELECT) return NULL;

    //Scan wholeObjects
    BOOL didScanWholeObject = [self scanSelectWholeObjectsWithScanner:scanner substitutionVariables:subsitutionVariable];
    if (didScanWholeObject) {
        return NULL;
    }

    //Scan a function
    id generalFunction = [self scanSelectFunctionWithScanner:scanner substitutionVariables:subsitutionVariable predefinedSelectFunctions:functions];
    if (generalFunction != nil) {
        return generalFunction;
    }

    //Scan a keyPath
    id fieldFunction = [self scanSelectKeyPathWithScanner:scanner substitutionVariables:subsitutionVariable];
    if (fieldFunction != nil) {
        return fieldFunction;
    }

    return NULL;
}



+(BOOL)scanSelectWholeObjectsWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BOOL didScanObjectSelector = [scanner scanString:@"*" intoString:NULL];
    return didScanObjectSelector;
}



+(id(^)(NSArray *))scanSelectFunctionWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable predefinedSelectFunctions:(NSDictionary *)functions
{
    BOOL didScanFunctionOpenDelimitter = [scanner scanString:@"@" intoString:NULL];
    if (!didScanFunctionOpenDelimitter) return nil;

    id(^function)(NSArray *objects, NSArray *parameters) = NULL;

    //Variable function...
    function = ({
        id variable = [self scanVariableWithScanner:scanner substitutionVariables:subsitutionVariable];
        BOOL didScanFunctionVariable = (variable != nil);
        if (didScanFunctionVariable && !isObjectABlock(variable)) {
    #ifdef DEBUG
            //This check is possibly unsafe as it relies on private implementation.
            [NSException raise:NSInvalidArgumentException format:@"Varible for SELECT function is not a block"];
            return nil;
    #endif
        }
         variable;
    });

    //predefined functions...
    BOOL shouldScanNamedFunction = (function == NULL);
    if (shouldScanNamedFunction) {
        NSString *functionName = [self scanIdentifierWithScanner:scanner];
        function = (functionName != nil) ? functions[functionName] : nil;
    }

    //Err...
    if (function == NULL) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid SELECT function."];
        return nil;
    }

    //Get the parameters for the function and curry it
    NSArray *parameters = [self scanSelectFunctionParametersWithScanner:scanner substitutionVariables:subsitutionVariable];
    return ^(NSArray *objects){
        return function(objects, parameters);
    };
}



+(NSArray *)scanSelectFunctionParametersWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BOOL didScanOpeningBrace = [scanner scanString:@"(" intoString:NULL];
    if (!didScanOpeningBrace) return nil;

    BOOL didScanImmediateClosingBrace = [scanner scanString:@")" intoString:NULL];
    if (didScanImmediateClosingBrace) return nil;

    NSMutableArray *parameters = [NSMutableArray new];
    do {        
        id identifier = [self scanIdentifierWithScanner:scanner];
        if (identifier != nil) {
            [parameters addObject:identifier];
            continue;
        }

        id value = [self scanValueWithScanner:scanner substitutionVariables:subsitutionVariable];
        if (value != nil) {
            [parameters addObject:value];
            continue;
        }

        [NSException raise:NSInvalidArgumentException format:@"Expected value in SELECT parameter list."];
        return nil;

    } while ([scanner scanString:@"," intoString:NULL]); //Scan parameter separator.

    BOOL didScanClosingBrace = [scanner scanString:@")" intoString:NULL];
    if (!didScanClosingBrace) {
        [NSException raise:NSInvalidArgumentException format:@"Failed to scan closing brace of SELECT function parameter list."];
        return nil;
    }

    return parameters;
}



+(id(^)(NSArray *))scanSelectKeyPathWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    NSString *keyPath = nil;

    //Scan a variable and check it's a string
    id variable = [self scanVariableWithScanner:scanner substitutionVariables:subsitutionVariable];
    BOOL didScanVariable = variable != nil;
    if (didScanVariable) {
        if (![variable isKindOfClass:NSString.class]) {
            [NSException raise:NSInvalidArgumentException format:@"Variable for SELECT clause is not a string"];
            return nil;
        }
        keyPath = variable;
    }

    //Scan an keyPath
    BOOL shouldScanKeyPath = (keyPath == nil);
    if (shouldScanKeyPath) {
        keyPath = [self scanKeyPathWithScanner:scanner];
    }

    //If we don't have a keyPath then we can't create a function
    if (keyPath == nil) return nil;

    //Create and return an keyPath select function
    return ^(NSArray *objects){
        NSMutableArray *results = [NSMutableArray new];
        for (id object in objects) {
            id result = [object valueForKeyPath:keyPath];
            NSAssert(result != nil, @"object <%@> does not yield a value for keyPath <%@>", object, keyPath);
            [results addObject:result];
        }

        return results;
    };
}



#pragma mark - WHERE
+(BCOWhereClauseExpression *)scanWhereClauseWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    //A query must start with 'WHERE'
    BOOL didScanWHEREDelimitter = [scanner scanString:@"WHERE" intoString:NULL];
    if (!didScanWHEREDelimitter) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid query. Queries must start with 'WHERE'"];
        return nil;
    }

    return [self scanWhereExpressionWithScanner:scanner substitutionVariables:subsitutionVariable];
}



+(BCOWhereClauseExpression *)scanWhereExpressionWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
//    NSLog(@"%@", [scanner.string substringToIndex:scanner.scanLocation]);

    BCOWhereClauseExpression *firstClause = nil;

    //isBracedExpression
    BOOL isBracedExpression = [scanner scanString:@"(" intoString:NULL];
    if (isBracedExpression) {

        id leftOperand = [self scanWhereExpressionWithScanner:scanner substitutionVariables:subsitutionVariable];
        //If there's a closing brace after the first operand then we've reached the end of the expression.
        BOOL isOrnamentalBracing = [scanner scanString:@")" intoString:NULL];

        firstClause = (isOrnamentalBracing) ? leftOperand : ({

            BCOQueryOperator operator = [self scanConjunctiveOperatorWithScanner:scanner];
            if (operator == BCOQueryOperatorInvalid) {
                [NSException raise:NSInvalidArgumentException format:@"Expected conjunctive ('AND' or 'OR')"];
                return nil;
            }

            id rightOperand = [self scanWhereExpressionWithScanner:scanner substitutionVariables:subsitutionVariable];

            BOOL didScanClosingBrace = [scanner scanString:@")" intoString:NULL];
            if (!didScanClosingBrace) {
                [NSException raise:NSInvalidArgumentException format:@"Expected closing brace (')')"];
                return nil;
            }

            [[BCOWhereClauseExpression alloc] initWithOperator:operator leftOperand:leftOperand rightOperand:rightOperand];
        });
    } else {
        //isPredicateExpression
        NSPredicate *predicate = [self scanPredicateWithScanner:scanner substitutionVariables:subsitutionVariable];
        BOOL isPredicateExpression = predicate != nil;
        if (isPredicateExpression) {
            firstClause = [[BCOWhereClauseExpression alloc] initWithOperator:BCOQueryOperatorPredicate leftOperand:predicate rightOperand:nil];
        } else {
            //isIndexExpression
            id leftOperand = [self scanIdentifierWithScanner:scanner];
            if (leftOperand == nil) {
                [NSException raise:NSInvalidArgumentException format:@"Expected index name."];
                return nil;
            }
            BCOQueryOperator operator = [self scanSetOperatorWithScanner:scanner];
            if (operator == BCOQueryOperatorInvalid) {
                [NSException raise:NSInvalidArgumentException format:@"Expected operator."];
                return nil;
            }

            id rightOperand = [self scanValueWithScanner:scanner substitutionVariables:subsitutionVariable];
            if (rightOperand == nil) {
                [NSException raise:NSInvalidArgumentException format:@"Expected value."];
                return nil;
            }

            firstClause = [[BCOWhereClauseExpression alloc] initWithOperator:operator leftOperand:leftOperand rightOperand:rightOperand];
        }
    }

    BCOQueryOperator possibleOperator = [self scanConjunctiveOperatorWithScanner:scanner];
    BOOL didEndClause = (possibleOperator == BCOQueryOperatorInvalid);
    if (didEndClause) {
        return firstClause;
    }

    id leftOperand = firstClause;
    BCOQueryOperator operator = possibleOperator;
    id rightOperand = [self scanWhereExpressionWithScanner:scanner substitutionVariables:subsitutionVariable];

    return [[BCOWhereClauseExpression alloc] initWithOperator:operator leftOperand:leftOperand rightOperand:rightOperand];
}



#pragma mark - GROUP BY
+(NSString *)scanGroupByClauseWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BOOL didScanGROUPBYDelimitter = [scanner scanString:@"GROUP BY" intoString:NULL];
    if (!didScanGROUPBYDelimitter) return nil;

    id variable = [self scanVariableWithScanner:scanner substitutionVariables:subsitutionVariable];
    BOOL didScanVariable = variable != nil;
    if (didScanVariable) {
        if (![variable isKindOfClass:NSString.class]) {
            [NSException raise:NSInvalidArgumentException format:@"Varaible for GROUP BY clause is not a string"];
            return nil;
        }
        return variable;
    }

    NSString *identifier = [self scanIdentifierWithScanner:scanner];
    BOOL didScanIdentifier = identifier != nil;
    if (!didScanIdentifier) {
        [NSException raise:NSInvalidArgumentException format:@"Failed to scan identifier for GROUP BY clause."];
        return nil;
    }

    return identifier;
}



#pragma mark ORDER BY
+(NSArray *)scanOrderByClauseWithScanner:(NSScanner *)scanner substitutionVariables:(NSDictionary *)subsitutionVariable
{
    BOOL didScanORDERBYDelimitter = [scanner scanString:@"ORDER BY" intoString:NULL];
    if (!didScanORDERBYDelimitter) return @[];

    NSMutableArray *sortDescriptors = [NSMutableArray new];
    do {
        //Attempt to scan a sort descriptor variable
        id sortDescriptor = [self scanVariableWithScanner:scanner substitutionVariables:subsitutionVariable];
        if ([sortDescriptor isKindOfClass:NSSortDescriptor.class]) {
            [sortDescriptors addObject:sortDescriptor];
            continue;
        } else if (sortDescriptor != nil) {
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
            //Consume a trailing ASC. We don't need to set it because the default is YES
            [scanner scanString:@"ASC" intoString:NULL];
        }
        //...and create a sort descriptor
        [sortDescriptors addObject:[NSSortDescriptor sortDescriptorWithKey:key ascending:ascending]];

    } while ([scanner scanString:@"," intoString:NULL]);

    return sortDescriptors;
}



#pragma mark - values
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
        NSMutableArray *array = [NSMutableArray new];

        do {
            id value = [self scanValueWithScanner:scanner substitutionVariables:substitutionVariables];
            if (value == nil) {
                [NSException raise:NSInvalidArgumentException format:@"Invalid collection. Expected value."];
                return nil;
            }
            [array addObject:value];
        } while ([scanner scanString:@"," intoString:NULL]);

        BOOL didScanCloseCollectionDelimitter = [scanner scanString:@"}" intoString:NULL];
        if (!didScanCloseCollectionDelimitter) {
            [NSException raise:NSInvalidArgumentException format:@"Invalid collection. Expected '}'"];
            return nil;
        }

        return array;
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



+(NSString *)scanKeyPathWithScanner:(NSScanner *)scanner
{
    BOOL didScanDot = NO;
    NSMutableArray *components = [NSMutableArray new];
    do {
        NSString *identifier = [self scanIdentifierWithScanner:scanner];
        if (identifier == nil)  break;

        [components addObject:identifier];
        didScanDot = [scanner scanString:@"." intoString:NULL];
    } while (didScanDot);

    if (components.count == 0) return nil;

    return [components componentsJoinedByString:@"."];
}



+(BCOQueryOperator)scanConjunctiveOperatorWithScanner:(NSScanner *)scanner
{
    //Note the trailing space to avoid ambiguous parsing
    if ([scanner scanString:@"AND " intoString:NULL] || [scanner scanString:@"and " intoString:NULL])  return BCOQueryOperatorAND;
    if ([scanner scanString:@"OR "  intoString:NULL] || [scanner scanString:@"or "  intoString:NULL])  return BCOQueryOperatorOR;

    return BCOQueryOperatorInvalid;
}



+(BCOQueryOperator)scanSetOperatorWithScanner:(NSScanner *)scanner
{
    //Note the trailing space to avoid ambiguous parsing
    if ([scanner scanString:@"= " intoString:NULL] || [scanner scanString:@"== " intoString:NULL])  return BCOQueryOperatorEqualTo;
    if ([scanner scanString:@"!= " intoString:NULL]) return BCOQueryOperatorNotEqualTo;

    if ([scanner scanString:@"IN " intoString:NULL]) return BCOQueryOperatorIn;
    if ([scanner scanString:@"in " intoString:NULL]) return BCOQueryOperatorIn;

    if ([scanner scanString:@"NOT IN " intoString:NULL]) return BCOQueryOperatorNotIn;
    if ([scanner scanString:@"not in " intoString:NULL]) return BCOQueryOperatorNotIn;

    //Note that the order of these scans is significant
    if ([scanner scanString:@"<= " intoString:NULL]) return BCOQueryOperatorLessThanOrEqualTo;
    if ([scanner scanString:@"< " intoString:NULL])  return BCOQueryOperatorLessThan;

    //Note that the order of these scans is significant
    if ([scanner scanString:@">= " intoString:NULL]) return BCOQueryOperatorGreaterThanOrEqualTo;
    if ([scanner scanString:@"> " intoString:NULL])  return BCOQueryOperatorGreaterThan;
    
    return BCOQueryOperatorInvalid;
}

@end
