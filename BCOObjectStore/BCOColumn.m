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
    NSMutableArray *_mutableIndexEntries;
    NSArray *_indexEntries;
}

-(instancetype)initWithIndexEntries:(NSArray *)objects columnDescription:(BCOColumnDescription *)columnDescription __attribute__((objc_designated_initializer));

@property(nonatomic, readonly) NSMutableSet *dirtyIndexEntries;

@end



@implementation BCOColumn

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexEntries:nil columnDescription:nil];
}



-(instancetype)initWithColumnDescription:(BCOColumnDescription *)columnDescription
{
    return [self initWithIndexEntries:[NSMutableArray new] columnDescription:columnDescription];
}



-(instancetype)initWithIndexEntries:(NSArray *)indexEntries columnDescription:(BCOColumnDescription *)columnDescription
{
    //BCOIndex assumes ownership of indexEntries and will modify it
    NSParameterAssert(columnDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexEntries = indexEntries;
    _mutableIndexEntries = nil; //We only create this if we need to and it's lazily created in the getter
    _columnDescription = columnDescription;

    _dirtyIndexEntries = [NSMutableSet new];


    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    if (![self isIndexEntriesDirty]) {
        return [[BCOColumn alloc] initWithIndexEntries:self.indexEntries columnDescription:self.columnDescription];
    }

    //Deep copy and replace dirty entries with a copy
    NSMutableArray *copy = [NSMutableArray new];
    NSSet *dirtyEntries = self.dirtyIndexEntries;

    for (BCOColumnEntry *entry in self.mutableIndexEntries) {
        BOOL mustCopy = [dirtyEntries containsObject:entry];
        BCOColumnEntry *shareableEntry = (mustCopy) ? [entry copy] : entry;
        [copy addObject:shareableEntry];
    }

    return [[BCOColumn alloc] initWithIndexEntries:copy columnDescription:self.columnDescription];
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



#pragma mark - value generation
-(id<BCOColumnValue>)generateColumnValueForObject:(id)object
{
    return self.columnDescription.columnValueGenerator(object);
}



#pragma mark - Entry Access
-(BCOColumnEntry *)entryForValue:(id)value index:(NSUInteger *)outIndex
{
    BCOMutableIndexEntry *referenceEntry = [[BCOMutableIndexEntry alloc] initWithValue:value objects:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.columnDescription.valueComparator];

    BCOColumnEntry *entry = (index == NSNotFound) ? nil : [entries objectAtIndex:index];

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
        BCOMutableIndexEntry *newEntry = [[BCOMutableIndexEntry alloc] initWithValue:value objects:[NSSet new]];

        [self.dirtyIndexEntries addObject:newEntry];

        NSMutableArray *objects = self.mutableIndexEntries;
        NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.columnDescription.valueComparator];
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



-(void)addRecord:(id)record forColumnValue:(id)value
{
    BCOMutableIndexEntry *entry = [self mutableEntryForValue:value index:NULL];
    [entry.objects addObject:record];
}



-(void)removeRecord:(id)record forColumnValue:(id)value
{
    NSUInteger index = NSNotFound;
    BCOMutableIndexEntry *entry = [self mutableEntryForValue:value index:&index];
    [entry.objects removeObject:record];

    if (entry.objects.count == 0) {
        [self.mutableIndexEntries removeObjectAtIndex:index];
    }
}



#pragma mark - Object Access
-(NSSet *)recordsForValue:(id)value
{
    BCOColumnEntry *entry = [self entryForValue:value index:NULL];
    return [entry.objects copy];
}



-(NSSet *)recordsForValuesInSet:(NSSet *)values
{
    NSMutableSet *objects = [NSMutableSet new];
    for (id value in values) {
        BCOColumnEntry *entry = [self entryForValue:value index:NULL];
        [objects unionSet:entry.objects];
    }

    return objects;
}



-(NSSet *)recordsWithValueLessThan:(id)value
{
#pragma message "TODO: This needs to handle values that are out side of array bounds"
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithValue:value objects:nil];
    NSArray *entries = self.indexEntries;
    //Index will 
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.columnDescription.valueComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanValue; i++) {
        BCOColumnEntry *entry = [entries objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    return matches;
}



-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value
{
#pragma message "TODO: This needs to handle values that are out side of array bounds"
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithValue:value objects:nil];
    NSArray *entries = self.indexEntries;
    //Index will
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanValue = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.columnDescription.valueComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanValue; i++) {
        BCOColumnEntry *entry = [entries objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    BCOColumnEntry *possibleExactMatch = entries[indexOfFirstObjectEqualToOrGreaterThanValue];
    if ([possibleExactMatch compare:referenceEntry] == NSOrderedSame) {
        [matches unionSet:possibleExactMatch.objects];
    }

    return matches;
}



-(NSSet *)recordsWithValueGreaterThan:(id)value
{
    //TODO:
    return [NSSet set];
}



-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value
{
    //TODO:
    return [NSSet set];
}



-(NSSet *)recordsWithValueNotEqualTo:(id)value
{
    NSMutableSet *matches = [NSMutableSet new];
    for (BCOColumnEntry *entry in self.indexEntries) {
        if ([entry.value compare:value]) continue;

        [matches unionSet:entry.objects];
    }

    return matches;
}

@end
