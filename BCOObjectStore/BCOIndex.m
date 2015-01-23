//
//  BCOIndex.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOIndex.h"
#import "BCOIndexEntry.h"



@interface BCOIndex ()
{
    NSMutableArray *_mutableIndexedObjects;
}
@property(nonatomic, readonly) BOOL ownsIndexedObjects;
@property(nonatomic, readonly) NSMutableArray *mutableIndexedObjects;
@property(nonatomic, readonly) NSMutableSet *ownedIndexEntries;

@end



@implementation BCOIndex

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithObjects:[NSMutableArray new] ownsObjects:YES];
}



-(instancetype)initWithObjects:(NSMutableArray *)objects ownsObjects:(BOOL)ownsObjects
{
    self = [super init];
    if (self == nil) return nil;

    _mutableIndexedObjects = objects;
    _ownsIndexedObjects = ownsObjects;

    _ownedIndexEntries = [NSMutableSet new];

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    return [[BCOIndex alloc] initWithObjects:_mutableIndexedObjects ownsObjects:NO];
}



#pragma mark - Properties
-(NSArray *)indexedObjects
{
    return _mutableIndexedObjects;
}



-(NSMutableArray *)mutableIndexedObjects
{
    if (_ownsIndexedObjects) return _mutableIndexedObjects;

    //Copy and own objects
    _mutableIndexedObjects = [_mutableIndexedObjects mutableCopy];
    _ownsIndexedObjects = YES;

    return _mutableIndexedObjects;
}



#pragma mark - Entry Access
-(BCOIndexEntry *)entryForKey:(id)key index:(NSUInteger *)outIndex
{
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *objects = self.indexedObjects;
    NSUInteger index = [objects indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];

    BCOIndexEntry *entry = (index == NSNotFound) ? nil : [objects objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



#pragma mark - Entry Updating
-(BCOIndexEntry *)mutableEntryForKey:(id)key index:(NSUInteger *)outIndex
{
    NSUInteger index = NSNotFound;
    BCOIndexEntry *entry = [self entryForKey:key index:&index];

    BOOL isOwned = (entry != nil) && ([self.ownedIndexEntries containsObject:entry]);
    if (isOwned) {
        if (outIndex != NULL) *outIndex = index;
        return entry;
    }

    BOOL shouldReplaceExistingEntry = entry != nil;
    if (shouldReplaceExistingEntry) {
        BCOIndexEntry *copy = [entry copy];
        [self.ownedIndexEntries addObject:copy];

        [self.mutableIndexedObjects replaceObjectAtIndex:index withObject:copy];
        if (outIndex != NULL) *outIndex = index;
        return copy;
    }

    //It's a new entry so own it and insert it into the array
    BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];
    [self.ownedIndexEntries addObject:newEntry];

    NSMutableArray *objects = self.mutableIndexedObjects;
    NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];
    [objects insertObject:newEntry atIndex:insertionIndex];

    if (outIndex != NULL) *outIndex = insertionIndex;
    return newEntry;
}



-(void)addObject:(id)object forKey:(id)key
{
    BCOIndexEntry *entry = [self mutableEntryForKey:key index:NULL];
    [entry.objects addObject:object];
}



-(void)removeObject:(id)object forKey:(id)key
{
    NSUInteger index = NSNotFound;
    BCOIndexEntry *entry = [self mutableEntryForKey:key index:&index];
    [entry.objects removeObject:object];

    if (entry.objects.count == 0) {
        [self.mutableIndexedObjects removeObjectAtIndex:index];
    }
}



#pragma mark - Object Access
-(NSSet *)objectsForKey:(id)key
{
    BCOIndexEntry *entry = [self entryForKey:key index:NULL];
    return entry.objects;
}



-(NSSet *)objectsForKeysInSet:(NSSet *)keys
{
    NSMutableSet *objects = [NSMutableSet new];
    for (id key in keys) {
        BCOIndexEntry *entry = [self entryForKey:key index:NULL];
        [objects unionSet:entry.objects];
    }

    return objects;
}



-(NSSet *)objectsLessThanKey:(id)key
{
#pragma message "TODO: This needs to handle keys that are out side of array bounds"
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *objects = self.indexedObjects;
    //Index will 
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [objects indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanKey; i++) {
        BCOIndexEntry *entry = [objects objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    return matches;
}



-(NSSet *)objectsLessThanOrEqualToKey:(id)key
{
#pragma message "TODO: This needs to handle keys that are out side of array bounds"
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *objects = self.indexedObjects;
    //Index will
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [objects indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanKey; i++) {
        BCOIndexEntry *entry = [objects objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    BCOIndexEntry *possibleExactMatch = objects[indexOfFirstObjectEqualToOrGreaterThanKey];
    if ([possibleExactMatch compare:referenceEntry] == NSOrderedSame) {
        [matches unionSet:possibleExactMatch.objects];
    }

    return matches;
}



-(NSSet *)objectsGreaterThanKey:(id)key
{
    //TODO:
    return [NSSet set];
}



-(NSSet *)objectsGreaterThanOrEqualToKey:(id)key
{
    //TODO:
    return [NSSet set];
}



-(NSSet *)objectsForKeysNotEqualToKey:(id)key
{
    NSMutableSet *matches = [NSMutableSet new];
    for (BCOIndexEntry *entry in self.indexedObjects) {
        if ([entry.key compare:key]) continue;

        [matches unionSet:entry.objects];
    }

    return matches;
}

@end
