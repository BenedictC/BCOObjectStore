//
//  BCOColumn.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOColumn.h"
#import "BCOColumnEntry.h"
#import "BCOColumnDescription.h"



@interface BCOColumn ()
{
    NSMutableArray *_mutableColumnEntries;
    NSArray *_columnEntries;
}

-(instancetype)initWithColumnEntries:(NSArray *)objects columnDescription:(BCOColumnDescription *)columnDescription __attribute__((objc_designated_initializer));

@property(nonatomic, readonly) NSMutableSet *dirtyColumnEntries;

@end



@implementation BCOColumn

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithColumnEntries:nil columnDescription:nil];
}



-(instancetype)initWithColumnDescription:(BCOColumnDescription *)columnDescription
{
    return [self initWithColumnEntries:[NSMutableArray new] columnDescription:columnDescription];
}



-(instancetype)initWithColumnEntries:(NSArray *)columnEntries columnDescription:(BCOColumnDescription *)columnDescription
{
    //BCOColumn assumes ownership of columnEntries and will modify it
    NSParameterAssert(columnDescription);

    self = [super init];
    if (self == nil) return nil;

    _columnEntries = columnEntries;
    _mutableColumnEntries = nil; //We only create this if we need to and it's lazily created in the getter
    _columnDescription = columnDescription;

    _dirtyColumnEntries = [NSMutableSet new];


    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    if (![self isColumnEntriesDirty]) {
        return [[BCOColumn alloc] initWithColumnEntries:self.columnEntries columnDescription:self.columnDescription];
    }

    //Deep copy and replace dirty entries with a copy
    NSMutableArray *copy = [NSMutableArray new];
    NSSet *dirtyEntries = self.dirtyColumnEntries;

    for (BCOColumnEntry *entry in self.mutableColumnEntries) {
        BOOL mustCopy = [dirtyEntries containsObject:entry];
        BCOColumnEntry *shareableEntry = (mustCopy) ? [entry copy] : entry;
        [copy addObject:shareableEntry];
    }

    return [[BCOColumn alloc] initWithColumnEntries:copy columnDescription:self.columnDescription];
}



#pragma mark - properties
-(NSArray *)columnEntries
{
    return ([self isColumnEntriesDirty]) ? _mutableColumnEntries : _columnEntries;
}



-(NSMutableArray *)mutableColumnEntries
{
    if (_mutableColumnEntries == nil) {
        _mutableColumnEntries = [_columnEntries mutableCopy];
        _columnEntries = nil; //We should never touch this now so we get rid of it.
    }

    return _mutableColumnEntries;
}



-(BOOL)isColumnEntriesDirty
{
    return (_mutableColumnEntries != nil);
}



-(NSComparator)entriesComparator
{
    NSComparator comparator = self.columnDescription.valueComparator;
    return ^NSComparisonResult(BCOColumnEntry *entry1, BCOColumnEntry *entry2) {
        return comparator(entry1.value, entry2.value);
    };
}



#pragma mark - value generation
-(id)generateColumnValueForObject:(id)object
{
    return self.columnDescription.columnValueGenerator(object);
}



#pragma mark - Entry Access
-(BCOColumnEntry *)entryForValue:(id)value index:(NSUInteger *)outIndex
{
    BCOMutableColumnEntry *referenceEntry = [[BCOMutableColumnEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.columnEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.entriesComparator];

    BCOColumnEntry *entry = (index == NSNotFound) ? nil : [entries objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



#pragma mark - Entry Updating
-(BCOMutableColumnEntry *)mutableEntryForValue:(id)value index:(NSUInteger *)outIndex
{
    NSUInteger index = NSNotFound;
    id entry = [self entryForValue:value index:&index];

    BOOL isNewEntry = entry == nil;
    if (isNewEntry) {
        //It's a new entry so own it and insert it into the array
        BCOMutableColumnEntry *newEntry = [[BCOMutableColumnEntry alloc] initWithValue:value records:[NSSet new]];

        [self.dirtyColumnEntries addObject:newEntry];

        NSMutableArray *objects = self.mutableColumnEntries;
        NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
        [objects insertObject:newEntry atIndex:insertionIndex];

        if (outIndex != NULL) *outIndex = insertionIndex;
        return newEntry;
    }

    BOOL isAlreadyDirty = (entry != nil) && [self.dirtyColumnEntries containsObject:entry];
    if (isAlreadyDirty) return entry;

    //We need to claim the entry
    BCOMutableColumnEntry *claimedEntry = [entry mutableCopy];
    [self.dirtyColumnEntries addObject:claimedEntry];
    [self.mutableColumnEntries replaceObjectAtIndex:index withObject:claimedEntry];

     return claimedEntry;
}



-(void)addRecord:(id)record forColumnValue:(id)value
{
    BCOMutableColumnEntry *entry = [self mutableEntryForValue:value index:NULL];
    [entry addRecord:record];
}



-(void)removeRecord:(id)record forColumnValue:(id)value
{
    NSUInteger index = NSNotFound;
    BCOMutableColumnEntry *entry = [self mutableEntryForValue:value index:&index];
    [entry removeRecord:record];

    if (entry.records.count == 0) {
        [self.mutableColumnEntries removeObjectAtIndex:index];
    }
}



#pragma mark - Collating Records from Entries
-(NSSet *)recordsFromEntriesInRange:(NSRange)range
{
    const NSInteger first = range.location;
    const NSInteger last = first + range.length;
    NSArray *entries = self.columnEntries;

    NSMutableSet *matchingRecords = [NSMutableSet new];
    for (int i = first; i < last; i++) {
        BCOColumnEntry *entry = entries[i];
        [matchingRecords unionSet:entry.records];
    }

    return matchingRecords;
}



#pragma mark - Record Access
-(NSSet *)recordsWithValueLessThan:(id)value
{
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.columnEntries;
    NSUInteger indexOfFirstObjectEqualToGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectEqualToGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value
{
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.columnEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(0, indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueGreaterThan:(id)value
{
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.columnEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingLastEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];
    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value
{
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithValue:value records:nil];
    NSArray *entries = self.columnEntries;
    NSUInteger indexOfFirstObjectGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.entriesComparator];

    NSRange range = NSMakeRange(indexOfFirstObjectGreaterThanValue, entries.count - indexOfFirstObjectGreaterThanValue);

    return [self recordsFromEntriesInRange:range];
}



-(NSSet *)recordsForValue:(id)value
{
    BCOColumnEntry *entry = [self entryForValue:value index:NULL];
    return entry.records;
}



-(NSSet *)recordsWithValueNotEqualTo:(id)value
{
    NSComparator comparator = self.columnDescription.valueComparator;

    NSMutableSet *records = [NSMutableSet new];
    for (BCOColumnEntry *entry in self.columnEntries) {
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
        BCOColumnEntry *entry = [self entryForValue:value index:NULL];
        [records unionSet:entry.records];
    }

    return records;
}



-(NSSet *)recordsForValuesNotInSet:(NSSet *)values
{
    NSMutableSet *shunnedEntries = [NSMutableSet new];
    for (id value in values) {
        BCOColumnEntry *shunnedEntry = [[BCOColumnEntry alloc] initWithValue:value records:nil];
        [shunnedEntries addObject:shunnedEntry];
    }

    NSMutableSet *records = [NSMutableSet new];
    for (BCOColumnEntry *entry in self.columnEntries) {
        BOOL shouldIgnoreRecords = [shunnedEntries containsObject:entry];

        if (shouldIgnoreRecords) continue;

        [records unionSet:entry.records];
    }

    return records;
}

@end
