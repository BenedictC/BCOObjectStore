//
//  BCOIndex.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOIndex.h"
#import "BCOIndexEntry.h"
#import "BCOIndexDescription.h"



@interface BCOIndex ()
{
    NSMutableArray *_mutableIndexEntries;
    NSArray *_indexEntries;
}

-(instancetype)initWithIndexEntries:(NSArray *)objects indexDescription:(BCOIndexDescription *)indexDescription __attribute__((objc_designated_initializer));

@property(nonatomic, readonly) NSMutableSet *dirtyIndexEntries;

@end



@implementation BCOIndex

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexEntries:nil indexDescription:nil];
}



-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription
{
    return [self initWithIndexEntries:[NSMutableArray new] indexDescription:indexDescription];
}



-(instancetype)initWithIndexEntries:(NSArray *)indexEntries indexDescription:(BCOIndexDescription *)indexDescription
{
    //BCOIndex assumes ownership of indexEntries and will modify it
    NSParameterAssert(indexDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexEntries = indexEntries;
    _mutableIndexEntries = nil; //We only create this if we need to and it's lazily created in the getter
    _indexDescription = indexDescription;

    _dirtyIndexEntries = [NSMutableSet new];


    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    if ([self isIndexEntriesDirty]) {
        return [[BCOIndex alloc] initWithIndexEntries:self.indexEntries indexDescription:self.indexDescription];
    }

    //Deep copy and replace dirty entries with a copy
    NSMutableArray *copy = [NSMutableArray new];
    NSSet *dirtyEntries = self.dirtyIndexEntries;

    for (BCOIndexEntry *entry in self.mutableIndexEntries) {
        BOOL mustCopy = [dirtyEntries containsObject:entry];
        BCOIndexEntry *shareableEntry = (mustCopy) ? [entry copy] : entry;
        [copy addObject:shareableEntry];
    }

    return [[BCOIndex alloc] initWithIndexEntries:copy indexDescription:self.indexDescription];
}



#pragma mark - properties
-(NSArray *)indexEntries
{
    return ([self isIndexEntriesDirty]) ? _mutableIndexEntries : _indexEntries;
}



-(NSMutableArray *)mutableIndexEntries
{
    if (_mutableIndexEntries == nil) {
        _mutableIndexEntries = [_indexEntries mutableCopy];
        _indexEntries = nil; //We should never touch this now so we get rid of it.
    }

    return _mutableIndexEntries;
}



-(BOOL)isIndexEntriesDirty
{
    return (_mutableIndexEntries != nil);
}



#pragma mark - Entry Access
-(BCOIndexEntry *)entryForKey:(id)key index:(NSUInteger *)outIndex
{
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *entries = self.indexEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.indexDescription.keyComparator];

    BCOIndexEntry *entry = (index == NSNotFound) ? nil : [entries objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



#pragma mark - Entry Updating
-(BCOIndexEntry *)mutableEntryForKey:(id)key index:(NSUInteger *)outIndex
{
    NSUInteger index = NSNotFound;
    BCOIndexEntry *entry = [self entryForKey:key index:&index];

    BOOL isNewEntry = entry == nil;
    if (isNewEntry) {
        //It's a new entry so own it and insert it into the array
        BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];

        [self.dirtyIndexEntries addObject:newEntry];

        NSMutableArray *objects = self.mutableIndexEntries;
        NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.keyComparator];
        [objects insertObject:newEntry atIndex:insertionIndex];

        if (outIndex != NULL) *outIndex = insertionIndex;
        return newEntry;
    }

    BOOL isAlreadyDirty = (entry != nil) && [self.dirtyIndexEntries containsObject:entry];
    if (isAlreadyDirty) return entry;

    //We need to claim the entry
    BCOIndexEntry *claimedEntry = [entry copy];
    [self.dirtyIndexEntries addObject:claimedEntry];
    [self.mutableIndexEntries replaceObjectAtIndex:index withObject:claimedEntry];

     return claimedEntry;
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
        [self.mutableIndexEntries removeObjectAtIndex:index];
    }
}



#pragma mark - Object Access
-(NSSet *)objectsForKey:(id)key
{
    BCOIndexEntry *entry = [self entryForKey:key index:NULL];
    return [entry.objects copy];
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
    NSArray *entries = self.indexEntries;
    //Index will 
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.keyComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanKey; i++) {
        BCOIndexEntry *entry = [entries objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    return matches;
}



-(NSSet *)objectsLessThanOrEqualToKey:(id)key
{
#pragma message "TODO: This needs to handle keys that are out side of array bounds"
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *entries = self.indexEntries;
    //Index will
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.keyComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanKey; i++) {
        BCOIndexEntry *entry = [entries objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    BCOIndexEntry *possibleExactMatch = entries[indexOfFirstObjectEqualToOrGreaterThanKey];
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
    for (BCOIndexEntry *entry in self.indexEntries) {
        if ([entry.key compare:key]) continue;

        [matches unionSet:entry.objects];
    }

    return matches;
}

@end
