//
//  BCOObjectStoreSnapshot.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"
#import "BCOIndexReference.h"
#import "BCOIndexEntry.h"



@interface BCOObjectStoreSnapshot ()
@property(readonly) NSDictionary *indexesByIndexName;
@property(readonly) NSMapTable *indexReferencesByObject;
@end



@implementation BCOObjectStoreSnapshot

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(objects);
    NSParameterAssert(indexDescriptions);

    self = [super init];
    if (self == nil) return nil;

    //Store ivars
    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build the indexReference table
    NSMapTable *indexReferencesByObject = [NSMapTable strongToStrongObjectsMapTable];
    for (id object in objects) {
        NSMutableSet *indexReferences = [NSMutableSet new];
        [indexReferencesByObject setObject:indexReferences forKey:object];
    }
    _indexReferencesByObject = indexReferencesByObject;

    //Build indexes
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    BCOReferenceIndexEntry *referenceEntry = [[BCOReferenceIndexEntry alloc] initWithKey:nil];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {

        //Create and add the index
        NSMutableArray *index = [NSMutableArray new];
        indexesByIndexName[indexName] = index;

        //Add each object to the index
        BCOIndexer indexer = indexDescription.indexer;
        for (id object in objects) {
            //Get the key and exit if the object shouldn't be included in this index
            id key = indexer(object);
            if (key == nil) continue;

            //Update the refrenceEntry so it will match the entry for key
            referenceEntry.key = key;

            //Find the entry in the index (or create if not present)
            BCOIndexEntry *entry = ^{
                NSUInteger entryIdx = [index indexOfObject:referenceEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];

                if (entryIdx != NSNotFound) return (BCOIndexEntry *)[index objectAtIndex:entryIdx];

                BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];
                NSUInteger insertionIdx = [index indexOfObject:newEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];
                [index insertObject:newEntry atIndex:insertionIdx];
                return newEntry;
            }();

            //Add the object to the entry
            [entry.objects addObject:object];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            NSMutableSet *referencesSet = [indexReferencesByObject objectForKey:object];
            [referencesSet addObject:reference];
        }
    }];
    _indexesByIndexName = indexesByIndexName;

    return self;
}



#pragma mark - 'copying'
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects
{
    NSSet *oldObjects = self.objects;
    NSMutableSet *freshObjects = [newObjects mutableCopy];
    [freshObjects minusSet:oldObjects];
    NSMutableSet *expiredObjects = [oldObjects mutableCopy];
    [expiredObjects minusSet:newObjects];

    return [self snapshotByRemovingObjects:expiredObjects addingObjects:freshObjects];
}



-(BCOObjectStoreSnapshot *)snapshotByRemovingObjects:(NSSet *)expiredObjects addingObjects:(NSSet *)freshObjects
{
    NSDictionary *indexDescriptions = self.indexDescriptions;
    NSSet *oldObjects = self.objects;

    NSMutableSet *newObjects = [oldObjects mutableCopy];
    //Perfrom a deep copy of the indexes
    NSMutableDictionary *newIndexesByIndexName = ({
        NSMutableDictionary *dict = [NSMutableDictionary new];
        [self.indexesByIndexName enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, NSArray *index, BOOL *stop) {
            dict[indexName] = [index mutableCopy];
        }];
        dict;
    });
    //Perform a deep copy of indexReferencesByObject
    NSMapTable *newIndexReferencesByObject = ({
        NSMapTable *table = [NSMapTable strongToStrongObjectsMapTable];
        NSMapTable *indexReferencesByObject = self.indexReferencesByObject;
        for (id key in indexReferencesByObject.keyEnumerator) {
            NSSet *existingReferencesSet = [indexReferencesByObject objectForKey:key];
            NSMutableSet *newReferencesSet = [existingReferencesSet mutableCopy];
            [table setObject:newReferencesSet forKey:key];
        }
        table;
    });

    BCOReferenceIndexEntry *referenceIndexEntry = [BCOReferenceIndexEntry new];

    //Remove expired objects from...
    for (id nonCanonicalExpiredObject in expiredObjects) {
        id expiredObject = [oldObjects member:nonCanonicalExpiredObject];
        if (expiredObject == nil) {
            NSLog(@"Attempting to remove an object not in the store");
            continue;
        }

        //.. all objects
        [newObjects removeObject:expiredObject];

        //...each index by enumerating the objects indexReferences
        NSSet *references = [newIndexReferencesByObject objectForKey:expiredObject];
        for (BCOIndexReference *reference in references) {
            NSMutableArray *index = newIndexesByIndexName[reference.indexName];
            referenceIndexEntry.key = reference.key;
            NSUInteger entryIndex = [index indexOfObject:referenceIndexEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];
            BCOIndexEntry *entry = [index objectAtIndex:entryIndex];
            [entry.objects removeObject:expiredObject];
            BOOL shouldRemoveEmptyEntry = entry.objects.count == 0;
            if (shouldRemoveEmptyEntry) {
                [index removeObjectAtIndex:entryIndex];
            }
        }

        //...the reference set (this has to happen after removing the object from the indexes)
        [newIndexReferencesByObject removeObjectForKey:expiredObject];
    }

    //Add freshObjects to...
    for (id freshObject in freshObjects) {
        id existingObject = [oldObjects member:freshObject];
        if (existingObject != nil) {
            NSLog(@"Store already contains object");
            continue;
        }

        //...all objects
        [newObjects addObject:freshObject];

        //... index references
        NSMutableSet *referencesSet = [NSMutableSet new];
        [newIndexReferencesByObject setObject:referencesSet forKey:freshObject];

        //...each index
        [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
            NSMutableArray *index = newIndexesByIndexName[indexName];
            BCOIndexer indexer = indexDescription.indexer;
            //Generate a key
            id key = indexer(freshObject);
            //Get the key and exit if the object shouldn't be included in this index
            if (key == nil) return;

            //Find the entry in the index (or create if not present)
            referenceIndexEntry.key = key;
            BCOIndexEntry *entry = ^{
                NSUInteger entryIdx = [index indexOfObject:referenceIndexEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingFirstEqual usingComparator:BCOIndexEntryComparator];

                if (entryIdx != NSNotFound) return (BCOIndexEntry *)[index objectAtIndex:entryIdx];

                BCOIndexEntry *newEntry = [[BCOIndexEntry alloc] initWithKey:key];
                NSUInteger insertionIdx = [index indexOfObject:newEntry inSortedRange:NSMakeRange(0, index.count) options:NSBinarySearchingInsertionIndex usingComparator:BCOIndexEntryComparator];
                [index insertObject:newEntry atIndex:insertionIdx];
                return newEntry;
            }();
            //Add the object to the index entry
            [entry.objects addObject:freshObject];

            //Add an indexReference to the referencesSet for the entry
            BCOIndexReference *reference = [[BCOIndexReference alloc] initWithIndexName:indexName key:key];
            [referencesSet addObject:reference];
        }];
    }

    //Construct the new snapshot
    BCOObjectStoreSnapshot *snapshot = [[BCOObjectStoreSnapshot alloc] init];
    snapshot->_indexDescriptions = indexDescriptions;
    snapshot->_objects = newObjects;
    snapshot->_indexesByIndexName = newIndexesByIndexName;
    snapshot->_indexReferencesByObject = newIndexReferencesByObject;

    return snapshot;
}




#pragma mark - object access
-(NSArray *)fetchObjectsMatching:(NSString *)matching sortDescriptors:(NSArray *)sortDescriptors
{
    return nil;
}

@end
