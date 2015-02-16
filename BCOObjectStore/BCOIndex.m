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
    NSParameterAssert(indexEntries);
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
    if (![self isIndexEntriesDirty]) {
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



-(NSComparator)entriesComparator
{
    NSComparator comparator = self.indexDescription.valueComparator;
    return ^NSComparisonResult(BCOIndexEntry *entry1, BCOIndexEntry *entry2) {
        return comparator(entry1.indexValue, entry2.indexValue);
    };
}



#pragma mark - value generation
-(id)generateIndexValueForObject:(id)object
{
    return self.indexDescription.indexValueGenerator(object);
}



#pragma mark - Entry Access
-(BCOIndexEntry *)entryForValue:(id)value index:(NSUInteger *)outIndex
{
    BCOMutableIndexEntry *referenceEntry = [[BCOMutableIndexEntry alloc] initWithIndexValue:value references:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.entriesComparator];

    BCOIndexEntry *entry = (index == NSNotFound) ? nil : [entries objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



#pragma mark - Entry Updating
-(BCOMutableIndexEntry *)mutableEntryForValue:(id)value index:(NSUInteger *)outIndex
{
    NSUInteger index = NSNotFound;
    id entry = [self entryForValue:value index:&index];

    BOOL isNewEntry = entry == nil;
    if (isNewEntry) {
        //It's a new entry so own it and insert it into the array
        BCOMutableIndexEntry *newEntry = [[BCOMutableIndexEntry alloc] initWithIndexValue:value references:[NSSet new]];

        [self.dirtyIndexEntries addObject:newEntry];

        NSMutableArray *objects = self.mutableIndexEntries;
        NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
        [objects insertObject:newEntry atIndex:insertionIndex];

        if (outIndex != NULL) *outIndex = insertionIndex;
        return newEntry;
    }

    if (outIndex != NULL) *outIndex = index;

    BOOL isAlreadyDirty = (entry != nil) && [self.dirtyIndexEntries containsObject:entry];
    if (isAlreadyDirty) return entry;

    //We need to claim the entry
    BCOMutableIndexEntry *claimedEntry = [entry mutableCopy];
    [self.dirtyIndexEntries addObject:claimedEntry];
    [self.mutableIndexEntries replaceObjectAtIndex:index withObject:claimedEntry];

    return claimedEntry;
}



-(void)addReference:(id)reference forIndexValue:(id)value
{
    BCOMutableIndexEntry *entry = [self mutableEntryForValue:value index:NULL];
    [entry addReference:reference];
}



-(void)removeReference:(id)reference forIndexValue:(id)value
{
    NSUInteger index = NSNotFound;
    BCOMutableIndexEntry *entry = [self mutableEntryForValue:value index:&index];
    [entry removeReference:reference];

    if (entry.references.count == 0) {
        [self.mutableIndexEntries removeObjectAtIndex:index];
    }
}



#pragma mark - Collating References from Entries
-(NSSet *)referencesFromEntriesInRange:(NSRange)range
{
    const NSInteger first = range.location;
    const NSInteger last = first + range.length;
    NSArray *entries = self.indexEntries;

    NSMutableSet *matchingReferences = [NSMutableSet new];
    for (NSInteger i = first; i < last; i++) {
        BCOIndexEntry *entry = entries[i];
        [matchingReferences unionSet:entry.references];
    }

    return matchingReferences;
}



#pragma mark - Reference Access
-(NSSet *)referencesWithValueLessThan:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value references:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectEqualToGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectEqualToGreaterThanValue);

    return [self referencesFromEntriesInRange:range];
}



-(NSSet *)referencesWithValueLessThanOrEqualTo:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value references:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectGreaterThanValue);

    return [self referencesFromEntriesInRange:range];
}



-(NSSet *)referencesWithValueGreaterThan:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value references:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self referencesFromEntriesInRange:range];
}



-(NSSet *)referencesWithValueGreaterThanOrEqualTo:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value references:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];

    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self referencesFromEntriesInRange:range];
}



-(NSSet *)referencesForValue:(id)value
{
    BCOIndexEntry *entry = [self entryForValue:value index:NULL];
    return entry.references;
}



-(NSSet *)referencesWithValueNotEqualTo:(id)value
{
    NSComparator comparator = self.indexDescription.valueComparator;

    NSMutableSet *references = [NSMutableSet new];
    for (BCOIndexEntry *entry in self.indexEntries) {
        if (comparator(entry.indexValue, value) != NSOrderedSame) {
            [references unionSet:entry.references];
        }
    }

    return references;
}



-(NSSet *)referencesForValuesInSet:(NSArray *)values
{
    NSMutableSet *references = [NSMutableSet new];
    for (id value in values) {
        BCOIndexEntry *entry = [self entryForValue:value index:NULL];
        [references unionSet:entry.references];
    }

    return references;
}



-(NSSet *)referencesForValuesNotInSet:(NSSet *)values
{
    NSMutableSet *shunnedEntries = [NSMutableSet new];
    for (id value in values) {
        BCOIndexEntry *shunnedEntry = [[BCOIndexEntry alloc] initWithIndexValue:value references:nil];
        [shunnedEntries addObject:shunnedEntry];
    }

    NSMutableSet *references = [NSMutableSet new];
    for (BCOIndexEntry *entry in self.indexEntries) {
        BOOL shouldIgnoreReferences = [shunnedEntries containsObject:entry];
        
        if (shouldIgnoreReferences) continue;
        
        [references unionSet:entry.references];
    }
    
    return references;
}

@end
