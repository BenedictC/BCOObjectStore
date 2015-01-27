//
//  BCOObjectStorageContainer.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOObjectStorageContainer.h"
#import "BCOStorageRecord.h"



@interface BCOObjectStorageContainer ()

@property(nonatomic, readonly) NSMutableDictionary *mutableObjectsByStorageRecords;

@end



@implementation BCOObjectStorageContainer

#pragma mark - instance life cycle
+(BCOObjectStorageContainer *)objectStorageWithObjects:(NSSet *)objects
{
    NSMutableDictionary *objectsByRecords = [NSMutableDictionary new];
    for (id object in objects) {
        BCOStorageRecord *record = [[BCOStorageRecord alloc] initWithObject:object];
        objectsByRecords[record] = object;
    }

    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:objectsByRecords];
}



+(BCOObjectStorageContainer *)objectStorageWithData:(NSData *)data
{
    if (data == nil) {
        return [BCOObjectStorageContainer new];
    }

    NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:data];

    NSAssert(objects != nil, @"Failed to un-archive objects.");

    NSMutableDictionary *objectsByStorageRecords = [NSMutableDictionary new];
    for (id object in objects) {
        BCOStorageRecord *record = [[BCOStorageRecord alloc] initWithObject:object];
        objectsByStorageRecords[record] = object;
    }

    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:objectsByStorageRecords];
}



-(instancetype)init
{
    return [self initWithObjectsByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithObjectsByStorageRecords:(NSMutableDictionary *)objectsByStorageRecords
{
    //BCOInMemoryObjectStorage assumes ownership of objectsByStorageRecords
    NSParameterAssert(objectsByStorageRecords);

    self = [super init];
    if (self == nil) return nil;

    _mutableObjectsByStorageRecords = objectsByStorageRecords;

    return self;
}



-(id)copyWithZone:(NSZone *)zone
{
    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:[_mutableObjectsByStorageRecords mutableCopy]];
}



#pragma mark - properties
-(NSData *)dataRepresentation
{
    NSArray *objects = self.mutableObjectsByStorageRecords.allValues;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:objects];

    return data;
}



-(NSDictionary *)objectsByStorageRecords
{
    return _mutableObjectsByStorageRecords;
}



#pragma mark - content managment
-(BCOStorageRecord *)addObject:(id)object
{
    BCOStorageRecord *record = [[BCOStorageRecord alloc] initWithObject:object];
    self.mutableObjectsByStorageRecords[record] = object;
    return record;
}



-(id)objectForStorageRecord:(BCOStorageRecord *)record
{
    return self.objectsByStorageRecords[record];
}



-(BCOStorageRecord *)storageRecordForObject:(id)object
{
    BCOStorageRecord *record = [[BCOStorageRecord alloc] initWithObject:object];

    id canonicalObject = self.objectsByStorageRecords[record];

    return (canonicalObject == nil) ? nil : record;
}



-(void)removeObjectForStorageRecord:(BCOStorageRecord *)record
{
    [self.mutableObjectsByStorageRecords removeObjectForKey:record];
}



-(NSArray *)allObjects
{
    return self.objectsByStorageRecords.allValues;
}



-(NSArray *)allStorageRecords
{
    return self.objectsByStorageRecords.allKeys;
}



-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block
{
    [self.objectsByStorageRecords enumerateKeysAndObjectsUsingBlock:block];
}

@end
