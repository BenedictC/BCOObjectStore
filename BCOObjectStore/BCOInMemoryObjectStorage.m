//
//  BCOInMemoryObjectStorage.m
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOInMemoryObjectStorage.h"
#import "BCOStorageRecord.h"



@interface BCOInMemoryObjectStorage ()

@property(nonatomic, readonly) NSMutableDictionary *mutableObjectsByStorageRecords;

@end



@implementation BCOInMemoryObjectStorage

#pragma mark - instance life cycle
+(BCOInMemoryObjectStorage *)objectStorageWithObjects:(NSSet *)objects
{
    NSMutableDictionary *objectsByRecords = [NSMutableDictionary new];
    for (id object in objects) {
        BCOStorageRecord *record = [[BCOStorageRecord alloc] initWithObject:object];
        objectsByRecords[record] = object;
    }

    return [[BCOInMemoryObjectStorage alloc] initWithObjectsByStorageRecords:objectsByRecords];
}



+(BCOInMemoryObjectStorage *)objectStorageWithData:(NSData *)data
{
    NSArray *objects = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    NSMutableDictionary *objectsByStorageRecords = [NSMutableDictionary new];
    for (id object in objects) {
        BCOStorageRecord *record = [[BCOStorageRecord alloc] initWithObject:object];
        objectsByStorageRecords[record] = object;
    }

    return [[BCOInMemoryObjectStorage alloc] initWithObjectsByStorageRecords:objectsByStorageRecords];
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
    return [[BCOInMemoryObjectStorage alloc] initWithObjectsByStorageRecords:[_mutableObjectsByStorageRecords mutableCopy]];
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
