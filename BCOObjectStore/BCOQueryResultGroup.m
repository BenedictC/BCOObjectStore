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
@property(nonatomic, readonly) id (^selectBlock)(NSArray *);

//Group properties
//@property(nonatomic, readonly) id objects;
@property(nonatomic, readonly) id groupIdentifier;

//Storage
@property(nonatomic, readonly) NSMutableDictionary *mutableGroups;
@property(nonatomic, readonly) NSMutableArray *mutableObjects;

//Caches
@property(nonatomic, readonly) id cachedObjectForGroupComparsion;
@property(nonatomic, readonly) id cachedResult;

@end



@implementation BCOQueryResultGroup

#pragma mark - factory
+(NSArray *)queryResultsWithObjects:(NSArray *)objects groupByField:(NSString *)groupByField sortDescriptors:(NSArray *)sortDescriptors selectBlock:(id (^)(NSArray *))selectBlock
{
    BCOQueryResultGroup *group = [[BCOQueryResultGroup alloc] initWithGroupByField:groupByField SortDescriptors:sortDescriptors groupIdentifier:nil selectBlock:selectBlock];
    for (id object in objects) {
        [group insertObject:object];
    }

    [group cacheResultsAndDiscardStorage];

    return [group result];
}



#pragma mark - instance life cycle
-(instancetype)initWithGroupByField:(NSString *)groupByField SortDescriptors:(NSArray *)sortDescriptors groupIdentifier:(id)groupIdentifier selectBlock:(id (^)(NSArray *))selectBlock
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



#pragma mark - equality
-(BOOL)isEqual:(id)object
{
    //We only care about the properties that are exposed in the BCOQueryResultGroup protocol    
    if (![object isKindOfClass:self.class]) return NO;

    id selfIdentifier = self.identifier;
    id otherIdentifer = [object identifier];
    if (selfIdentifier == nil && otherIdentifer != nil) return NO;
    if (selfIdentifier != nil && otherIdentifer == nil) return NO;
    if (![selfIdentifier isEqual:otherIdentifer])       return NO;

    id selfResult = self.result;
    id otherResult = [object result];
    if (selfResult == nil && otherResult != nil) return NO;
    if (selfResult != nil && otherResult == nil) return NO;
    if (![selfResult isEqual:otherResult])       return NO;

    return YES;
}



-(NSUInteger)hash
{
    //We only care about the properties that are exposed in the BCOQueryResultGroup protocol
    NSUInteger hash = 0;

    hash ^= [self.identifier hash];
    hash ^= [self.result hash];

    return hash;
}



#pragma mark - properties
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> {identifier: %@, result:\n%@}", NSStringFromClass(self.class), self, self.groupIdentifier, self.result];
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



-(id)mappedObjects
{
    //Map the objects if necessary
    NSArray *objects = self.mutableObjects;
    id (^selectBlock)(NSArray *) = self.selectBlock;

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



-(id)result
{
    if (_cachedResult != nil) {
        return _cachedResult;
    }

    return ([self isGrouped]) ? [self orderedGroups] : [self mappedObjects];
}



-(NSArray *)objects
{
    id objects = self.result;
    return ([objects isKindOfClass:NSArray.class]) ? objects : nil;
}



-(NSUInteger)numberOfObjects
{
    NSArray *objects = self.objects;
    return (objects == nil) ? 0 : objects.count;
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
    NSAssert(_cachedResult == nil, @"Attempted to insert an object into a completed result group.");

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
    _cachedResult = [self result];

    //...AndDiscardStorage
    _mutableGroups = nil;
    _mutableObjects = nil;
}

@end
