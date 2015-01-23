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



#pragma mark - properties
-(NSArray *)indexObjects
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



#pragma mark - object access
-(NSSet *)objectsForKey:(id)key
{
    BCOIndexEntry *entry = [self entryForKey:key index:NULL];
    return entry.objects;
}



-(BCOIndexEntry *)entryForKey:(id)key index:(NSUInteger *)outIndex
{
    BCOIndexReferenceEntry *referenceEntry = [[BCOIndexReferenceEntry alloc] initWithKey:key];
    NSArray *objects = self.indexObjects;
    NSUInteger index = [objects indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];

    BCOIndexEntry *entry = (index == NSNotFound) ? nil : [objects objectAtIndex:index];

    if (outIndex != NULL) *outIndex = index;
    return entry;
}



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

@end
