//
//  BCOQueryResultGroup.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 03/02/2015.
//
//

#import "BCOQueryResultGroup.h"



@interface BCOQueryResultGroup ()
@property(nonatomic, readonly) NSString *groupByField;
@property(nonatomic, readonly) NSArray *sortDescriptors;
@property(nonatomic, readonly) NSArray *(^selectBlock)(NSArray *);

@property(nonatomic, readonly) id groupIdentifier;

@property(nonatomic, readonly) NSMutableArray *objects;
@property(nonatomic, readonly) NSMutableDictionary *groups;
@end



@implementation BCOQueryResultGroup

#pragma mark - factory
+(NSArray *)queryResultsWithObjects:(NSArray *)objects groupByField:(NSString *)groupByField sortDescriptors:(NSArray *)sortDescriptors selectBlock:(NSArray *(^)(NSArray *))selectBlock
{
    BCOQueryResultGroup *group = [[BCOQueryResultGroup alloc] initWithGroupByField:groupByField SortDescriptors:sortDescriptors groupIdentifier:nil selectBlock:selectBlock];
    for (id object in objects) {
        [group insertObject:object];
    }

#pragma message "calculate orderedGroups and orderedObjects now rather than lazily of get"

    return [group results];
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
    _objects = (isGrouped) ?  nil : [NSMutableArray new];
    _groups =  (isGrouped) ? [NSMutableDictionary new] : nil;

    return self;
}



#pragma mark - properties
-(NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> {identifier: %@, objects:\n%@}", NSStringFromClass(self.class), self, self.groupIdentifier, self.results];
}



-(BOOL)isGrouped
{
    return _groupByField != nil;
}



-(NSArray *)orderedGroups
{
    NSMutableArray *orderedGroups = [NSMutableArray new];

    NSArray *sortDescriptors = self.sortDescriptors;
    for (BCOQueryResultGroup *group in self.groups.objectEnumerator) {
        NSUInteger insertionIdx = [orderedGroups indexOfObject:group inSortedRange:NSMakeRange(0, orderedGroups.count) options:NSBinarySearchingInsertionIndex usingComparator:^NSComparisonResult(BCOQueryResultGroup *group1, BCOQueryResultGroup *group2) {
            //TODO: What if the the sort descriptors are DESC? Should we pick lastObject?
            id obj1 = [group1.objects firstObject];
            id obj2 = [group2.objects firstObject];
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
    NSArray *objects = self.objects;
    NSArray *(^selectBlock)(NSArray *) = self.selectBlock;

    return (selectBlock == NULL) ? objects : selectBlock(objects);
}



#pragma mark - BCOQueryResultGroup protocol
-(id)identifier
{
    return _groupIdentifier;
}



-(NSArray *)results
{
    return ([self isGrouped]) ? [self orderedGroups] : [self orderedObjects];
}



#pragma mark - mutating
-(void)insertObjectIntoGroup:(id)object
{
    id groupIdentifer = [object valueForKey:self.groupByField];

    NSMutableDictionary *groups = self.groups;
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
    if ([self isGrouped]) {
        [self insertObjectIntoGroup:object];
        return;
    }

    NSMutableArray *objects = self.objects;
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

@end
