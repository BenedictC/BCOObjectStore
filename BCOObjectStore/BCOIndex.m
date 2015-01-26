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

-(instancetype)initWithIndexEntries:(NSMutableArray *)objects indexDefinition:(BCOIndexDescription *)definition __attribute__((objc_designated_initializer));

@property(nonatomic, readonly) NSMutableArray *mutableIndexEntries;

@end



@implementation BCOIndex

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithIndexEntries:nil indexDefinition:nil];
}



-(instancetype)initWithIndexDefinition:(BCOIndexDescription *)definition
{
    return [self initWithIndexEntries:[NSMutableArray new] indexDefinition:definition];
}



-(instancetype)initWithIndexEntries:(NSMutableArray *)indexEntries indexDefinition:(BCOIndexDescription *)definition
{
    //BCOIndex assumes ownership of indexEntries and will modify it
    NSParameterAssert(definition);

    self = [super init];
    if (self == nil) return nil;

    _mutableIndexEntries = indexEntries;
    _definition = definition;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    //Deep copy entries
    NSMutableArray *entries = [NSMutableArray new];
    for (BCOIndexEntry *entry in self.mutableIndexEntries) {
        [entries addObject:[entry copy]];
    }

    return [[BCOIndex alloc] initWithIndexEntries:entries indexDefinition:self.definition];
}



#pragma mark - Entry Access
-(BCOIndexEntry *)entryForKey:(id)key index:(NSUInteger *)outIndex
{
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *entries = self.mutableIndexEntries;
    NSUInteger index = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual usingComparator:self.definition.keyComparator];

    BCOIndexEntry *entry = (index == NSNotFound) ? nil : [entries objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



#pragma mark - Entry Updating
-(BCOIndexEntry *)mutableEntryForKey:(id)key index:(NSUInteger *)outIndex
{
    NSUInteger index = NSNotFound;
    BCOIndexEntry *entry = [self entryForKey:key index:&index];
    if (entry != nil) return entry;

    //It's a new entry so own it and insert it into the array
    BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];

    NSMutableArray *objects = self.mutableIndexEntries;
    NSUInteger insertionIndex = [objects indexOfObject:newEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:self.definition.keyComparator];
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
    NSArray *entries = self.mutableIndexEntries;
    //Index will 
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.definition.keyComparator];

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
    NSArray *entries = self.mutableIndexEntries;
    //Index will
    NSUInteger indexOfFirstObjectEqualToOrGreaterThanKey = [entries indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, entries.count) options:NSBinarySearchingFirstEqual | NSBinarySearchingInsertionIndex usingComparator:self.definition.keyComparator];

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
    for (BCOIndexEntry *entry in self.mutableIndexEntries) {
        if ([entry.key compare:key]) continue;

        [matches unionSet:entry.objects];
    }

    return matches;
}

@end
