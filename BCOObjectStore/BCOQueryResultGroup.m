//
//  BCOQueryResultGroup.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 03/02/2015.
//
//

#import "BCOQueryResultGroup.h"



@interface BCOQueryResultGroup ()

//Query parameters
@property(nonatomic, readonly) NSString *groupByField;
@property(nonatomic, readonly) NSArray *sortDescriptors;
@property(nonatomic, readonly) NSArray *(^selectBlock)(NSArray *);

//Group properties
//@property(nonatomic, readonly) id objects;
@property(nonatomic, readonly) id groupIdentifier;

//Storage
@property(nonatomic, readonly) NSMutableDictionary *mutableGroups;
@property(nonatomic, readonly) NSMutableArray *mutableObjects;

//Caches
@property(nonatomic, readonly) id cachedObjectForGroupComparsion;
@property(nonatomic, readonly) NSArray *cachedObjects;

@end



@implementation BCOQueryResultGroup

#pragma mark - factory
+(NSArray *)queryResultsWithObjects:(NSArray *)objects groupByField:(NSString *)groupByField sortDescriptors:(NSArray *)sortDescriptors selectBlock:(NSArray *(^)(NSArray *))selectBlock
{
    BCOQueryResultGroup *group = [[BCOQueryResultGroup alloc] initWithGroupByField:groupByField SortDescriptors:sortDescriptors groupIdentifier:nil selectBlock:selectBlock];
    for (id object in objects) {
        [group insertObject:object];
    }

    [group cacheResultsAndDiscardStorage];

    return [group objects];
}



#pragma mark - instance life cycle
-(instancetype)initWithGroupByField:(NSString *)groupByField SortDescriptors:(NSArray *)sortDescriptors groupIdentifier:(id)groupIdentifier selectBlock:(NSArray *(^)(NSArray *))selectBlock
{
    self = [super init];
    if (self == nil) return nil;

    _groupByField = [groupByField copy];
    _sortDescriptors = [sortDescriptors copy];
    _groupIdentifier = groupIdentifier;
    _selectBlock = selectBlock;

    BOOL isGrouped = (groupByField != nil);
    _mutableObjects = (isGrouped) ?  nil : [NSMutableArray new];
    _mutableGroups  = (isGrouped) ? [NSMutableDictionary new] : nil;

    return self;
}



#pragma mark - properties
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> {identifier: %@, objects:\n%@}", NSStringFromClass(self.class), self, self.groupIdentifier, self.objects];
}



-(BOOL)isGrouped
{
    return _groupByField != nil;
}



-(NSArray *)orderedGroups
{
    NSMutableArray *orderedGroups = [NSMutableArray new];

    NSArray *sortDescriptors = self.sortDescriptors;
    for (BCOQueryResultGroup *group in self.mutableGroups.objectEnumerator) {
        NSUInteger insertionIdx = [orderedGroups indexOfObject:group inSortedRange:NSMakeRange(0, orderedGroups.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(BCOQueryResultGroup *group1, BCOQueryResultGroup *group2) {
            //TODO: What if the the sort descriptors are DESC? Should we pick lastObject?
            id obj1 = [group1 objectForGroupComparsion];
            id obj2 = [group2 objectForGroupComparsion];
            //Try each sort descriptor
            for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
                NSComparisonResult result = [sortDescriptor compareObject:obj1 toObject:obj2];
                if (result != NSOrderedSame)  return result;
            }
            //Default to ordered the same.
            return NSOrderedSame;
        }];

        [orderedGroups insertObject:group atIndex:insertionIdx];
    }

    return orderedGroups;
}



-(NSArray *)orderedObjects
{
    //Map the objects if necessary
    NSArray *objects = self.mutableObjects;
    NSArray *(^selectBlock)(NSArray *) = self.selectBlock;

    return (selectBlock == NULL) ? objects : selectBlock(objects);
}



-(id)objectForGroupComparsion
{
    if (_cachedObjectForGroupComparsion != nil) {
        return _cachedObjectForGroupComparsion;
    }

    NSAssert(NO, @"This should not happen!");
    return [self.mutableObjects firstObject];
}



#pragma mark - BCOQueryResultGroup protocol
-(id)identifier
{
    return _groupIdentifier;
}



-(NSArray *)objects
{
    if (_cachedObjects != nil) {
        return _cachedObjects;
    }

    return ([self isGrouped]) ? [self orderedGroups] : [self orderedObjects];
}



-(NSUInteger)numberOfObjects
{
    return self.objects.count;
}



#pragma mark - mutating
-(void)insertObjectIntoGroup:(id)object
{
    id groupIdentifer = [object valueForKey:self.groupByField];

    NSMutableDictionary *groups = self.mutableGroups;
    BCOQueryResultGroup *group = groups[groupIdentifer];
    if (group == nil) {
        //Create and insert a group
        BCOQueryResultGroup *insertionGroup = [[BCOQueryResultGroup alloc] initWithGroupByField:nil SortDescriptors:self.sortDescriptors groupIdentifier:groupIdentifer selectBlock:self.selectBlock];
        groups[groupIdentifer] = insertionGroup;

        group = insertionGroup;
    }

    [group insertObject:object];
}



-(void)insertObject:(id)object
{
    NSAssert(_cachedObjects == nil, @"Attempted to insert an object into a completed result group.");

    if ([self isGrouped]) {
        [self insertObjectIntoGroup:object];
        return;
    }

    NSMutableArray *objects = self.mutableObjects;
    NSArray *sortDescriptors = self.sortDescriptors;
    NSUInteger insertionIndex = [objects indexOfObject:object inSortedRange:NSMakeRange(0, objects.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(id obj1, id obj2) {
        //Try each sort descriptor
        for (NSSortDescriptor *sortDescriptor in sortDescriptors) {
            NSComparisonResult result = [sortDescriptor compareObject:obj1 toObject:obj2];
            if (result != NSOrderedSame)  return result;
        }
        //Default to ordered the same.
        return NSOrderedSame;
    }];
    [objects insertObject:object atIndex:insertionIndex];
}



-(void)cacheResultsAndDiscardStorage
{
    //cacheResults...
    for (BCOQueryResultGroup *group in self.mutableGroups.objectEnumerator) {
        [group cacheResultsAndDiscardStorage];
    }
    _cachedObjectForGroupComparsion = [self.mutableObjects firstObject];
    _cachedObjects = [self objects];

    //...AndDiscardStorage
    _mutableGroups = nil;
    _mutableObjects = nil;
}

@end
