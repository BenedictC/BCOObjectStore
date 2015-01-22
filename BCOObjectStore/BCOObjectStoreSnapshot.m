//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"
#import "BCOIndexEntryReference.h"
#import "BCOIndexEntry.h"



@interface BCOObjectStoreSnapshot ()
@property(readonly) NSDictionary *indexesByIndexName;
@property(readonly) NSMapTable *indexEntryReferencesByObject;
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(objects);
    NSParameterAssert(indexDescriptions);

    self = [super init];
    if (self == nil) return nil;

    //Store ivars
    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build the indexReference table
    NSMapTable *indexEntryReferencesByObject = [NSMapTable strongToStrongObjectsMapTable];
    for (id object in objects) {
        NSMutableSet *indexReferences = [NSMutableSet new];
        [indexEntryReferencesByObject setObject:indexReferences forKey:object];
    }
    _indexEntryReferencesByObject = indexEntryReferencesByObject;

    //Build indexes
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    BCOReferenceIndexEntry *referenceEntry = [[BCOReferenceIndexEntry alloc] initWithKey:nil];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {        

        //Create and add the index
        NSMutableArray *index = [NSMutableArray new];
        indexesByIndexName[indexName] = index;

        //Add each object to the index
        BCOIndexer indexer = indexDescription.indexer;
        for (id object in objects) {
            //Get the key and exit if the object shouldn't be included in this index
            id key = indexer(object);
            if (key == nil) continue;

            //Update the refrenceEntry so it will match the entry for key
            referenceEntry.key = key;

            //Find the entry in the index (or create if not present)
            BCOIndexEntry *entry = ^{
                NSUInteger entryIdx = [index indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];

                if (entryIdx != NSNotFound) return (BCOIndexEntry *)[index objectAtIndex:entryIdx];

                BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];
                NSUInteger insertionIdx = [index indexOfObject:newEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];
                [index insertObject:newEntry atIndex:insertionIdx];
                return newEntry;
            }();

            //Add the object to the entry
            [entry.objects addObject:object];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexEntryReference *reference = [[BCOIndexEntryReference alloc] initWithIndexName:indexName key:key];
            NSMutableSet *referencesSet = [indexEntryReferencesByObject objectForKey:object];
            [referencesSet addObject:reference];
        }
    }];
    _indexesByIndexName = indexesByIndexName;

    return self;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    NSSet *oldObjects = self.objects;
    NSMutableSet *freshObjects = [newObjects mutableCopy];
    [freshObjects minusSet:oldObjects];
    NSMutableSet *expiredObjects = [oldObjects mutableCopy];
    [expiredObjects minusSet:newObjects];

    return [self snapshotByRemovingObjects:expiredObjects addingObjects:freshObjects];
}



-(BCOObjectStoreSnapshot *)snapshotByRemovingObjects:(NSSet *)expiredObjects addingObjects:(NSSet *)freshObjects
{
    NSDictionary *indexDescriptions = self.indexDescriptions;
    NSSet *oldObjects = self.objects;

    NSMutableSet *newObjects = [oldObjects mutableCopy];
    //Perfrom a deep copy of the indexes
    NSMutableDictionary *newIndexesByIndexName = ({
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, NSArray *index, BOOL *stop) {
            dict[indexName] = [index mutableCopy];
        }];
        dict;
    });
    //Perform a deep copy of indexEntryReferencesByObject
    NSMapTable *newIndexEntryReferencesByObject = ({
        NSMapTable *table = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable *indexEntryReferencesByObject = self.indexEntryReferencesByObject;
        for (id key in indexEntryReferencesByObject.keyEnumerator) {
            NSSet *existingReferencesSet = [indexEntryReferencesByObject objectForKey:key];
            NSMutableSet *newReferencesSet = [existingReferencesSet mutableCopy];
            [table setObject:newReferencesSet forKey:key];
        }
        table;
    });

    BCOReferenceIndexEntry *referenceIndexEntry = [BCOReferenceIndexEntry new];

    //Remove expired objects from...
    for (id nonCanonicalExpiredObject in expiredObjects) {
        id expiredObject = [oldObjects member:nonCanonicalExpiredObject];
        if (expiredObject == nil) {
            NSLog(@"Attempting to remove an object not in the store");
            continue;
        }

        //.. all objects
        [newObjects removeObject:expiredObject];

        //...each index by enumerating the objects indexReferences
        NSSet *references = [newIndexEntryReferencesByObject objectForKey:expiredObject];
        for (BCOIndexEntryReference *reference in references) {
            NSMutableArray *index = newIndexesByIndexName[reference.indexName];
            referenceIndexEntry.key = reference.key;
            NSUInteger entryIndex = [index indexOfObject:referenceIndexEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];
            BCOIndexEntry *entry = [index objectAtIndex:entryIndex];
            [entry.objects removeObject:expiredObject];
            BOOL shouldRemoveEmptyEntry = entry.objects.count == 0;
            if (shouldRemoveEmptyEntry) {
                [index removeObjectAtIndex:entryIndex];
            }
        }

        //...the reference set (this has to happen after removing the object from the indexes)
        [newIndexEntryReferencesByObject removeObjectForKey:expiredObject];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        id existingObject = [oldObjects member:freshObject];
        if (existingObject != nil) {
            NSLog(@"Store already contains object");
            continue;
        }

        //...all objects
        [newObjects addObject:freshObject];

        //... index references
        NSMutableSet *referencesSet = [NSMutableSet new];
        [newIndexEntryReferencesByObject setObject:referencesSet forKey:freshObject];

        //...each index
        [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
            NSMutableArray *index = newIndexesByIndexName[indexName];
            BCOIndexer indexer = indexDescription.indexer;
            //Generate a key
            id key = indexer(freshObject);
            //Get the key and exit if the object shouldn't be included in this index
            if (key == nil) return;

            //Find the entry in the index (or create if not present)
            referenceIndexEntry.key = key;
            BCOIndexEntry *entry = ^{
                NSUInteger entryIdx = [index indexOfObject:referenceIndexEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];

                if (entryIdx != NSNotFound) return (BCOIndexEntry *)[index objectAtIndex:entryIdx];

                BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];
                NSUInteger insertionIdx = [index indexOfObject:newEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];
                [index insertObject:newEntry atIndex:insertionIdx];
                return newEntry;
            }();
            //Add the object to the index entry
            [entry.objects addObject:freshObject];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexEntryReference *reference = [[BCOIndexEntryReference alloc] initWithIndexName:indexName key:key];
            [referencesSet addObject:reference];
        }];
    }

    //Construct the new snapshot
    BCOObjectStoreSnapshot *snapshot = [[BCOObjectStoreSnapshot alloc] init];
    snapshot->_indexDescriptions = indexDescriptions;
    snapshot->_objects = newObjects;
    snapshot->_indexesByIndexName = newIndexesByIndexName;
    snapshot->_indexEntryReferencesByObject = newIndexEntryReferencesByObject;

    return snapshot;
}



#pragma mark - object access
-(NSArray *)executeQuery:(NSString *)query
{
    return [self executeQuery:query subsitutionVariable:nil];
}


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



#define MUST(EXPR, ...) ({if (!(EXPR)) {[NSException raise:NSInvalidArgumentException format:__VA_ARGS__]; return nil; } })
-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable
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

        NSSet *objects = [self fetchObjectsFromIndex:indexName operator:operator value:value];
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



-(NSSet *)fetchObjectsFromIndex:(NSString *)indexName operator:(BCOOperator)operator value:(id)value
{
    NSLog(@"'%@' '%@' '%@'", indexName, @(operator), value);

    NSArray *index = self.indexesByIndexName[indexName];

    switch (operator) {
        case BCOOperatorEqualTo: {
            NSSet *keySet = [NSSet setWithObject:value];
            return [self fetchObjectsFromIndex:index withKeyInKeySet:keySet];
        }
        case BCOOperatorIn: {
            return [self fetchObjectsFromIndex:index withKeyInKeySet:value];
        }

        default:
            break;
    }

    return nil;
}



-(NSSet *)fetchObjectsFromIndex:(NSArray *)index withKeyInKeySet:(NSSet *)keySet
{

    BCOReferenceIndexEntry *referenceIndexEntry = [[BCOReferenceIndexEntry alloc] initWithKey:nil];
    NSMutableSet *results = [NSMutableSet new];

    for (id key in keySet) {
        referenceIndexEntry.key = key;
        NSUInteger indexEntryIdx = [index indexOfObject:referenceIndexEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];
        if (indexEntryIdx == NSNotFound) continue;

        BCOIndexEntry *entry = [index objectAtIndex:indexEntryIdx];
        [results unionSet:entry.objects];
    }

    return results;
}

@end
