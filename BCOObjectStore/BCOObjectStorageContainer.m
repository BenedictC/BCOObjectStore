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

+(NSMutableDictionary *)readObjectsAndRecordsFromPath:(NSString *)objectsPath
{
    NSMutableDictionary *objectsByStorageRecords = [NSMutableDictionary new];
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:objectsPath];
    [stream open];

    do {
        //Read the length
        NSInteger dataLength = 0;
        [stream read:(uint8_t *)&dataLength maxLength:sizeof(NSInteger)];

        if (stream.streamStatus == NSStreamStatusAtEnd) break;

        //Read the data
        NSInteger bytesRemaining = dataLength;
        void *buffer = malloc(sizeof(uint8_t) * dataLength);
        while (bytesRemaining > 0) {
            bytesRemaining -= [stream read:buffer maxLength:bytesRemaining];
        }

        //Create the object from the data
        NSData *archive = [NSData dataWithBytesNoCopy:buffer length:dataLength freeWhenDone:YES];
        id object = [NSKeyedUnarchiver unarchiveObjectWithData:archive];

        //Create a record and store
        BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];
        objectsByStorageRecords[record] = object;
    } while (stream.streamStatus != NSStreamStatusAtEnd);
    
    [stream close];

    return objectsByStorageRecords;
}



+(BOOL)writeObjects:(NSArray *)objects toPath:(NSString *)objectsPath error:(NSError **)outError
{
    NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
    [stream open];

    for (id object in objects) {
        NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:object];

        //Write the length
        {
            const NSInteger scalarToWrite = archive.length;
            const uint8_t *bytes = (uint8_t *)&scalarToWrite;
            const NSInteger totalBytes = sizeof(scalarToWrite);

            NSInteger bytesWritten = 0;
            while (bytesWritten < totalBytes) {
                bytesWritten += [stream write:bytes+(bytesWritten) maxLength:(totalBytes-bytesWritten)];
            }
        }

        //Write the data
        {
            const uint8_t *bytes = (uint8_t *)archive.bytes;
            const NSInteger totalBytes = archive.length;

            NSInteger bytesWritten = 0;
            while (bytesWritten < totalBytes) {
                bytesWritten += [stream write:bytes+(bytesWritten) maxLength:(totalBytes-bytesWritten)];
            }
        }
    }

    [stream close];
    NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];

    return [data writeToFile:objectsPath options:NSDataWritingAtomic error:outError];
}



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



+(BCOObjectStorageContainer *)objectStorageWithPersistentStorePath:(NSString *)path
{
    //Attempt to load objects
    NSString *objectsPath = [path stringByAppendingPathComponent:@"objects.archive"];
    NSData *archive = [NSData dataWithContentsOfFile:objectsPath];
    if (archive == nil) {
        return [BCOObjectStorageContainer new];
    }

    //Load objects
    NSMutableDictionary *objectsByStorageRecords = [self readObjectsAndRecordsFromPath:path];
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



#pragma mark - Content updating
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



-(void)removeObjectForStorageRecord:(BCOStorageRecord *)record
{
    BOOL isObjectInStore = self.objectsByStorageRecords[record] != nil;
    if (!isObjectInStore) {
        NSLog(@"Attempting to remove an object not in the store");
        return;
    }

    [self.mutableObjectsByStorageRecords removeObjectForKey:record];
}



#pragma mark - Random content access
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



#pragma mark - Enumerated content access
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



#pragma mark - Archiving
-(BOOL)writeToPath:(NSString *)path error:(NSError **)outError
{
    NSString *objectsPath = [path stringByAppendingPathComponent:@"objects.archive"];

    return [self.class writeObjects:self.objectsByStorageRecords.allValues toPath:objectsPath error:outError];
}

@end
