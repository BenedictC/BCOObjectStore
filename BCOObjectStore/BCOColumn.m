//
//  BCOColumn.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOColumn.h"
#import "BCOColumnEntry.h"
#import "BCOIndexColumnDescription.h"



@interface BCOColumn ()
{
    NSMutableArray *_mutableIndexEntries;
    NSArray *_indexEntries;
}

-(instancetype)initWithIndexEntries:(NSArray *)objects indexColumnDescription:(BCOIndexColumnDescription *)indexColumnDescription __attribute__((objc_designated_initializer));

@property(nonatomic, readonly) NSMutableSet *dirtyIndexEntries;

@end



@implementation BCOColumn

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexEntries:nil indexColumnDescription:nil];
}



-(instancetype)initWithIndexColumnDescription:(BCOIndexColumnDescription *)indexColumnDescription
{
    return [self initWithIndexEntries:[NSMutableArray new] indexColumnDescription:indexColumnDescription];
}



-(instancetype)initWithIndexEntries:(NSArray *)indexEntries indexColumnDescription:(BCOIndexColumnDescription *)indexColumnDescription
{
    //BCOIndex assumes ownership of indexEntries and will modify it
    NSParameterAssert(indexColumnDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexEntries = indexEntries;
    _mutableIndexEntries = nil; //We only create this if we need to and it's lazily created in the getter
    _indexColumnDescription = indexColumnDescription;

    _dirtyIndexEntries = [NSMutableSet new];


    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    if (![self isIndexEntriesDirty]) {
        return [[BCOColumn alloc] initWithIndexEntries:self.indexEntries indexColumnDescription:self.indexColumnDescription];
    }

    //Deep copy and replace dirty entries with a copy
    NSMutableArray *copy = [NSMutableArray new];
    NSSet *dirtyEntries = self.dirtyIndexEntries;

    for (BCOColumnEntry *entry in self.mutableIndexEntries) {
        BOOL mustCopy = [dirtyEntries containsObject:entry];
        BCOColumnEntry *shareableEntry = (mustCopy) ? [entry copy] : entry;
        [copy addObject:shareableEntry];
    }

    return [[BCOColumn alloc] initWithIndexEntries:copy indexColumnDescription:self.indexColumnDescription];
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



#pragma mark - key generation
-(id<BCOColumnKey>)generateColumnKeyForObject:(id)object
{
    return self.indexColumnDescription.indexKeyGenerator(object);
}



#pragma mark - Entry Access
-(BCOColumnEntry *)entryForKey:(id)key index:(NSUInteger *)outIndex
{
    BCOMutableIndexEntry *referenceEntry = [[BCOMutableIndexEntry alloc] initWithKey:key objects:nil];
    NSArray *entries = self.indexEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.indexColumnDescription.keyComparator];

    BCOColumnEntry *entry = (index == NSNotFound) ? nil : [entries objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



#pragma mark - Entry Updating
-(BCOMutableIndexEntry *)mutableEntryForKey:(id)key index:(NSUInteger *)outIndex
{
    NSUInteger index = NSNotFound;
    id entry = [self entryForKey:key index:&index];

    BOOL isNewEntry = entry == nil;
    if (isNewEntry) {
        //It's a new entry so own it and insert it into the array
        BCOMutableIndexEntry *newEntry = [[BCOMutableIndexEntry alloc] initWithKey:key objects:[NSSet new]];

        [self.dirtyIndexEntries addObject:newEntry];

        NSMutableArray *objects = self.mutableIndexEntries;
        NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.indexColumnDescription.keyComparator];
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



-(void)addRecord:(id)record forKey:(id)key
{
    BCOMutableIndexEntry *entry = [self mutableEntryForKey:key index:NULL];
    [entry.objects addObject:record];
}



-(void)removeRecord:(id)record forKey:(id)key
{
    NSUInteger index = NSNotFound;
    BCOMutableIndexEntry *entry = [self mutableEntryForKey:key index:&index];
    [entry.objects removeObject:record];

    if (entry.objects.count == 0) {
        [self.mutableIndexEntries removeObjectAtIndex:index];
    }
}



#pragma mark - Object Access
-(NSSet *)recordsForKey:(id)key
{
    BCOColumnEntry *entry = [self entryForKey:key index:NULL];
    return [entry.objects copy];
}



-(NSSet *)recordsForKeysInSet:(NSSet *)keys
{
    NSMutableSet *objects = [NSMutableSet new];
    for (id key in keys) {
        BCOColumnEntry *entry = [self entryForKey:key index:NULL];
        [objects unionSet:entry.objects];
    }

    return objects;
}



-(NSSet *)recordsLessThanKey:(id)key
{
#pragma message "TODO: This needs to handle keys that are out side of array bounds"
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithKey:key objects:nil];
    NSArray *entries = self.indexEntries;
    //Index will 
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexColumnDescription.keyComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanKey; i++) {
        BCOColumnEntry *entry = [entries objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    return matches;
}



-(NSSet *)recordsLessThanOrEqualToKey:(id)key
{
#pragma message "TODO: This needs to handle keys that are out side of array bounds"
    BCOColumnEntry *referenceEntry = [[BCOColumnEntry alloc] initWithKey:key objects:nil];
    NSArray *entries = self.indexEntries;
    //Index will
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.indexColumnDescription.keyComparator];

    NSMutableSet *matches = [NSMutableSet set];
    for (NSUInteger i = 0; i < indexOfFirstObjectEqualToOrGreaterThanKey; i++) {
        BCOColumnEntry *entry = [entries objectAtIndex:i];
        [matches unionSet:entry.objects];
    }

    BCOColumnEntry *possibleExactMatch = entries[indexOfFirstObjectEqualToOrGreaterThanKey];
    if ([possibleExactMatch compare:referenceEntry] == NSOrderedSame) {
        [matches unionSet:possibleExactMatch.objects];
    }

    return matches;
}



-(NSSet *)recordsGreaterThanKey:(id)key
{
    //TODO:
    return [NSSet set];
}



-(NSSet *)recordsGreaterThanOrEqualToKey:(id)key
{
    //TODO:
    return [NSSet set];
}



-(NSSet *)recordsForKeysNotEqualToKey:(id)key
{
    NSMutableSet *matches = [NSMutableSet new];
    for (BCOColumnEntry *entry in self.indexEntries) {
        if ([entry.key compare:key]) continue;

        [matches unionSet:entry.objects];
    }

    return matches;
}

@end
