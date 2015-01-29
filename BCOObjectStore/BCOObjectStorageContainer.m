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
{
    NSMutableDictionary *_mutableObjectsByStorageRecords;
    NSDictionary *_objectsByStorageRecords;
}

@end



@implementation BCOObjectStorageContainer

#pragma mark - instance life cycle
+(BCOObjectStorageContainer *)objectStorageWithObjects:(NSSet *)objects
{
    NSMutableDictionary *objectsByRecords = [NSMutableDictionary new];
    for (id object in objects) {
        BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];
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
        BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];
        objectsByStorageRecords[record] = object;
    }

    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:objectsByStorageRecords];
}



-(instancetype)init
{
    return [self initWithObjectsByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithObjectsByStorageRecords:(NSDictionary *)objectsByStorageRecords
{
    NSParameterAssert(objectsByStorageRecords);

    self = [super init];
    if (self == nil) return nil;

    _objectsByStorageRecords = objectsByStorageRecords;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    //Don't share an object that we're allowed to write to
    NSDictionary *shareableObjectsByStorageRecords = ([self isObjectsByStorageRecordsDirty]) ? [self.objectsByStorageRecords copy] : self.objectsByStorageRecords;

    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:shareableObjectsByStorageRecords];
}



#pragma mark - properties
-(NSData *)dataRepresentation
{
    NSArray *objects = self.objectsByStorageRecords.allValues;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:objects];

    return data;
}



-(BOOL)isObjectsByStorageRecordsDirty
{
    return _mutableObjectsByStorageRecords != nil;
}



-(NSDictionary *)objectsByStorageRecords
{
    return ([self isObjectsByStorageRecordsDirty]) ? _mutableObjectsByStorageRecords : _objectsByStorageRecords;
}



-(NSMutableDictionary *)mutableObjectsByStorageRecords
{
    if (_mutableObjectsByStorageRecords != nil) return _mutableObjectsByStorageRecords;

    _mutableObjectsByStorageRecords = [_objectsByStorageRecords mutableCopy];
    _objectsByStorageRecords = nil;

    return _mutableObjectsByStorageRecords;
}



#pragma mark - content managment
-(BCOStorageRecord *)addObject:(id)object
{
    BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];

    BOOL isObjectAlreadyInStore = self.objectsByStorageRecords[record] != nil;
    if (isObjectAlreadyInStore) {
        NSLog(@"Store already contains object");
        return record;
    }

    self.mutableObjectsByStorageRecords[record] = object;
    return record;
}



-(id)objectForStorageRecord:(BCOStorageRecord *)record
{
    return self.objectsByStorageRecords[record];
}



-(BCOStorageRecord *)storageRecordForObject:(id)object
{
    BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];

    id canonicalObject = self.objectsByStorageRecords[record];

    return (canonicalObject == nil) ? nil : record;
}



-(void)removeObjectForStorageRecord:(BCOStorageRecord *)record
{
    BOOL isObjectInStore = self.objectsByStorageRecords[record] != nil;
    if (!isObjectInStore) {
        NSLog(@"Attempting to remove an object not in the store");
        return;
    }

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
