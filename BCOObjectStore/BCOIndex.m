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
        return comparator(entry1.value, entry2.value);
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
    BCOMutableIndexEntry *referenceEntry = [[BCOMutableIndexEntry alloc] initWithValue:value records:nil];
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
        BCOMutableIndexEntry *newEntry = [[BCOMutableIndexEntry alloc] initWithValue:value records:[NSSet new]];

        [self.dirtyIndexEntries addObject:newEntry];

        NSMutableArray *objects = self.mutableIndexEntries;
        NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
        [objects insertObject:newEntry atIndex:insertionIndex];

        if (outIndex != NULL) *outIndex = insertionIndex;
        return newEntry;
    }

    BOOL isAlreadyDirty = (entry != nil) && [self.dirtyIndexEntries containsObject:entry];
    if (isAlreadyDirty) return entry;

    //We need to claim the entry
    BCOMutableIndexEntry *claimedEntry = [entry mutableCopy];
    [self.dirtyIndexEntries addObject:claimedEntry];
    [self.mutableIndexEntries replaceObjectAtIndex:index withObject:claimedEntry];

     return claimedEntry;
}



-(void)addRecord:(id)record forIndexValue:(id)value
{
    BCOMutableIndexEntry *entry = [self mutableEntryForValue:value index:NULL];
    [entry addRecord:record];
}



-(void)removeRecord:(id)record forIndexValue:(id)value
{
    NSUInteger index = NSNotFound;
    BCOMutableIndexEntry *entry = [self mutableEntryForValue:value index:&index];
    [entry removeRecord:record];

    if (entry.records.count == 0) {
        [self.mutableIndexEntries removeObjectAtIndex:index];
    }
}



#pragma mark - Collating Records from Entries
-(NSSet *)recordsFromEntriesInRange:(NSRange)range
{
    const NSInteger first = range.location;
    const NSInteger last = first + range.length;
    NSArray *entries = self.indexEntries;

    NSMutableSet *matchingRecords = [NSMutableSet new];
    for (int i = first; i < last; i++) {
        BCOIndexEntry *entry = entries[i];
        [matchingRecords unionSet:entry.records];
    }

    return matchingRecords;
}



#pragma mark - Record Access
-(NSSet *)recordsWithValueLessThan:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectEqualToGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectEqualToGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueGreaterThan:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];

    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsForValue:(id)value
{
    BCOIndexEntry *entry = [self entryForValue:value index:NULL];
    return entry.records;
}



-(NSSet *)recordsWithValueNotEqualTo:(id)value
{
    NSComparator comparator = self.indexDescription.valueComparator;

    NSMutableSet *records = [NSMutableSet new];
    for (BCOIndexEntry *entry in self.indexEntries) {
        if (comparator(entry.value, value) != NSOrderedSame) {
            [records unionSet:entry.records];
        }
    }

    return records;
}



-(NSSet *)recordsForValuesInSet:(NSSet *)values
{
    NSMutableSet *records = [NSMutableSet new];
    for (id value in values) {
        BCOIndexEntry *entry = [self entryForValue:value index:NULL];
        [records unionSet:entry.records];
    }

    return records;
}



-(NSSet *)recordsForValuesNotInSet:(NSSet *)values
{
    NSMutableSet *shunnedEntries = [NSMutableSet new];
    for (id value in values) {
        BCOIndexEntry *shunnedEntry = [[BCOIndexEntry alloc] initWithValue:value records:nil];
        [shunnedEntries addObject:shunnedEntry];
    }

    NSMutableSet *records = [NSMutableSet new];
    for (BCOIndexEntry *entry in self.indexEntries) {
        BOOL shouldIgnoreRecords = [shunnedEntries containsObject:entry];

        if (shouldIgnoreRecords) continue;

        [records unionSet:entry.records];
    }

    return records;
}

@end
