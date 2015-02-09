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



@implementation BCOIndexDescription (EntryComparator)

-(NSComparator)entriesComparator
{
    NSComparator comparator = self.valueComparator;
    return ^NSComparisonResult(BCOIndexEntry *entry1, BCOIndexEntry *entry2) {
        return comparator(entry1.indexValue, entry2.indexValue);
    };
}

@end




@interface BCOIndex ()

@property(nonatomic, readonly) NSArray *indexEntries;

@end



@implementation BCOIndex

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexEntries:nil indexDescription:nil];
}



-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription
{
    return [self initWithIndexEntries:[NSArray new] indexDescription:indexDescription];
}



-(instancetype)initWithIndexEntries:(NSArray *)indexEntries indexDescription:(BCOIndexDescription *)indexDescription
{
    //BCOIndex assumes ownership of indexEntries and will modify it
    NSParameterAssert(indexEntries);
    NSParameterAssert(indexDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexEntries = indexEntries;
    _indexDescription = indexDescription;

    return self;
}



#pragma mark - Entry Access
-(BCOIndexEntry *)entryForValue:(id)value index:(NSUInteger *)outIndex
{
    BCOMutableIndexEntry *referenceEntry = [[BCOMutableIndexEntry alloc] initWithIndexValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.indexDescription.entriesComparator];

    if (outIndex != NULL) *outIndex = index;
    return (index == NSNotFound) ? nil : [entries objectAtIndex:index];
}



#pragma mark - Collating Records from Entries
-(NSSet *)recordsFromEntriesInRange:(NSRange)range
{
    const NSInteger first = range.location;
    const NSInteger last = first + range.length;
    NSArray *entries = self.indexEntries;

    NSMutableSet *matchingRecords = [NSMutableSet new];
    for (NSInteger i = first; i < last; i++) {
        BCOIndexEntry *entry = entries[i];
        [matchingRecords unionSet:entry.records];
    }

    return matchingRecords;
}



#pragma mark - Record Access
-(NSSet *)recordsWithValueLessThan:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectEqualToGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectEqualToGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueGreaterThan:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.entriesComparator];
    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value
{
    BCOIndexEntry *referenceEntry = [[BCOIndexEntry alloc] initWithIndexValue:value records:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.entriesComparator];

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
        if (comparator(entry.indexValue, value) != NSOrderedSame) {
            [records unionSet:entry.records];
        }
    }

    return records;
}



-(NSSet *)recordsForValuesInSet:(NSArray *)values
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
        BCOIndexEntry *shunnedEntry = [[BCOIndexEntry alloc] initWithIndexValue:value records:nil];
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



@interface BCOIndexBuilder ()
@property(nonatomic, readonly) NSMutableArray *sortedEntries;
@property(nonatomic, readonly) NSMutableSet *ownedIndexEntries;
@end



@implementation BCOIndexBuilder

#pragma mark - instance life cycle
+(instancetype)builderWithPreviousIndex:(BCOIndex *)index
{
    return [[BCOIndexBuilder alloc] initWithIndexDescription:index.indexDescription sortedEntires:[index indexEntries]];
}



+(instancetype)builderWithIndexDescription:(BCOIndexDescription *)indexDescription
{
    return [[BCOIndexBuilder alloc] initWithIndexDescription:indexDescription sortedEntires:nil];
}



-(instancetype)init
{
    return [self initWithIndexDescription:nil sortedEntires:nil];
}



-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription sortedEntires:(NSArray *)sortedEntries
{
    NSParameterAssert(indexDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexDescription = indexDescription;
    _sortedEntries = [sortedEntries mutableCopy] ?: [NSMutableArray new];

    return self;

}



#pragma mark - value generation
-(id)generateIndexValueForObject:(id)object
{
    return self.indexDescription.indexValueGenerator(object);
}



#pragma mark - Entry Updating
-(BCOMutableIndexEntry *)mutableEntryForValue:(id)value index:(NSUInteger *)outIndex
{
    BCOMutableIndexEntry *referenceEntry = [[BCOMutableIndexEntry alloc] initWithIndexValue:value records:nil];

    NSMutableArray *sortedEntries = self.sortedEntries;

    NSUInteger existingIndex = [sortedEntries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, sortedEntries.count) options:NSBinarySearchingFirstEqual usingComparator:self.indexDescription.entriesComparator];
    BOOL didFindExistingEntry = existingIndex != NSNotFound;
    if (didFindExistingEntry) {
        BCOMutableIndexEntry *existingEntry = [sortedEntries objectAtIndex:existingIndex];

        BOOL mustCopyEntry = ![self.ownedIndexEntries containsObject:existingEntry];

        BCOMutableIndexEntry *entry = (mustCopyEntry) ? ({
            //Replace the existing entry with a copy that we own
            BCOMutableIndexEntry *copy = [existingEntry mutableCopy];
            [self.ownedIndexEntries addObject:copy];
            [sortedEntries replaceObjectAtIndex:existingIndex withObject:copy];
            copy;
        }) : existingEntry;

        if (outIndex != NULL) *outIndex = existingIndex;
        return entry;
    }

    //It's a new entry so own it and insert it into the array
    BCOMutableIndexEntry *newEntry = referenceEntry; //We reuse the refrence entry because it's not been used for anything else
    [self.ownedIndexEntries addObject:newEntry];
    NSUInteger insertionIndex = [sortedEntries indexOfObject:newEntry inSortedRange:NSMakeRange(0, sortedEntries.count) options:NSBinarySearchingInsertionIndex usingComparator:self.indexDescription.entriesComparator];
    [sortedEntries insertObject:newEntry atIndex:insertionIndex];

    if (outIndex != NULL) *outIndex = insertionIndex;
    return newEntry;
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
        [self.sortedEntries removeObjectAtIndex:index];
    }
}



-(BCOIndex *)finalize
{
    NSAssert(_sortedEntries != nil, @"");
    BCOIndex *index = [[BCOIndex alloc] initWithIndexEntries:self.sortedEntries indexDescription:self.indexDescription];

    _sortedEntries = nil;
    _ownedIndexEntries = nil;

    return index;
}


@end

