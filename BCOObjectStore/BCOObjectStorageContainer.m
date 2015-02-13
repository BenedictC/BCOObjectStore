//
//  BCOObjectStorageContainer.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOObjectStorageContainer.h"
#import "BCOStorageRecord.h"



#pragma mark - Interfaces

@interface BCOObjectStorageContainer ()

@property(nonatomic, readonly) NSDictionary *objectsByStorageRecords;
@property(nonatomic, readonly) BCOObjectStorageContainer *previousContainer;
@end



@interface BCOObjectStorageEnumerator : NSObject <BCOObjectStorageEnumerator>

-(instancetype)initWithStorageContainer:(BCOObjectStorageContainer *)storageContainer records:(id<NSFastEnumeration>)records;
@property(nonatomic, readonly) BCOObjectStorageContainer *storageContainer;
@property(nonatomic, readonly) id<NSFastEnumeration> records;

@end





#pragma mark - BCOObjectStorageContainer

@implementation BCOObjectStorageContainer

#pragma mark - Archiving
+(NSMutableDictionary *)readAllObjectsAndRecordsFromPath:(NSString *)objectsPath objectDeserializer:(id(^)(NSData *))deserializer
{
    NSMutableDictionary *objectsByStorageRecords = [NSMutableDictionary new];
    NSInputStream *stream = [NSInputStream inputStreamWithFileAtPath:objectsPath];
    [stream open];

    do {
        //Read the length
        uint32_t dataLength = 0;
        [stream read:(uint8_t *)&dataLength maxLength:sizeof(dataLength)];

        if (stream.streamStatus == NSStreamStatusAtEnd) break;

        //Read the data
        uint32_t bytesRemaining = dataLength;
        void *buffer = malloc(sizeof(uint8_t) * dataLength);
        while (bytesRemaining > 0) {
            bytesRemaining -= [stream read:buffer maxLength:bytesRemaining];
        }

        //Create the object from the data
        NSData *archive = [NSData dataWithBytesNoCopy:buffer length:dataLength freeWhenDone:YES];
        id object = deserializer(archive);

        //Create a record and store
        BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];
        objectsByStorageRecords[record] = object;
    } while (stream.streamStatus != NSStreamStatusAtEnd);

    [stream close];

    return objectsByStorageRecords;
}



+(id)readObjectAtOffset:(NSInteger)offset fromPath:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:NULL];
    if (data == nil) return nil;

    const uint32_t archiveLength = ({
        uint32_t result;
        memcpy(&result, data.bytes + offset, sizeof(result));
        result;
    });
    const uint32_t archiveOffset = offset + sizeof(archiveLength);
    NSData *archive = [data subdataWithRange:NSMakeRange(archiveOffset, archiveLength)];

    return [NSKeyedUnarchiver unarchiveObjectWithData:archive];
}



+(BOOL)writeObjects:(NSArray *)objects toPath:(NSString *)objectsPath objectSerializer:(NSData *(^)(id))serializer error:(NSError **)outError
{
    NSOutputStream *stream = [NSOutputStream outputStreamToMemory];
    [stream open];

    for (id object in objects) {
        NSData *archive = serializer(object);

        //Write the length
        {
            const uint32_t scalarToWrite = archive.length;
            const uint8_t *bytes = (uint8_t *)&scalarToWrite;
            const uint32_t totalBytes = sizeof(scalarToWrite);

            uint32_t bytesWritten = 0;
            while (bytesWritten < totalBytes) {
                bytesWritten += [stream write:bytes+(bytesWritten) maxLength:(totalBytes-bytesWritten)];
            }
        }

        //Write the data
        {
            const uint8_t *bytes = (uint8_t *)archive.bytes;
            const uint32_t totalBytes = archive.length;

            uint32_t bytesWritten = 0;
            while (bytesWritten < totalBytes) {
                bytesWritten += [stream write:bytes+(bytesWritten) maxLength:(totalBytes-bytesWritten)];
            }
        }
    }

    [stream close];
    NSData *data = [stream propertyForKey:NSStreamDataWrittenToMemoryStreamKey];

    return [data writeToFile:objectsPath options:NSDataWritingAtomic error:outError];
}



+(BCOObjectStorageContainer *)objectStorageWithPersistentStorePath:(NSString *)path objectDeserializer:(id(^)(NSData *))deserializer error:(NSError **)outError
{
    //Attempt to load objects
    NSString *objectsPath = [path stringByAppendingPathComponent:@"objects.archive"];
    NSData *archive = [NSData dataWithContentsOfFile:objectsPath];
    if (archive == nil) {
        //TODO: Should we return an error?
        return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:@{}];
    }

    //Load objects
    NSMutableDictionary *objectsByStorageRecords = [self readAllObjectsAndRecordsFromPath:objectsPath objectDeserializer:deserializer];
    if (objectsByStorageRecords == nil) {
        //TODO: Should we return an error?
        return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:@{}];
    }

    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:objectsByStorageRecords];
}



//+(NSString *)latestStorageRecordsPathInDirectoryAtPath:(NSString *)directoryPath version:(NSInteger *)outVersion error:(NSError **)outError
//{
//    //Load latest index
//    NSFileManager *fileManager = [NSFileManager new];
//    NSError *error = nil;
//    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:directoryPath error:&error];
//    if (directoryContents == nil) {
//        //TODO: Wrap the error in a domain specific error
//        if (outError != NULL)  *outError = error;
//        return nil;
//    }
//
//    NSRegularExpression *matchIndexFile = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+\\.index$" options:NSRegularExpressionCaseInsensitive error:NULL];
//    NSInteger latestVersion = 0;
//    NSString *latestVersionFilename = nil;
//    for (NSString *filename in directoryContents) {
//        NSTextCheckingResult *result = [matchIndexFile firstMatchInString:filename options:0 range:NSMakeRange(0, [filename length])];
//        if (result == nil) continue;
//
//        const NSInteger version = [filename integerValue]; //NSString.h states that trailing non-integer characters are discarded.
//
//        BOOL isLater = version > latestVersion;
//        if (!isLater) continue;
//
//        latestVersion = version;
//        latestVersionFilename = filename;
//    }
//
//    if (latestVersionFilename == nil) return nil;
//
//    if (outVersion != NULL)  *outVersion = latestVersion;
//    NSString *path = [directoryPath stringByAppendingPathComponent:latestVersionFilename];
//    return path;
//}



-(BOOL)writeToPath:(NSString *)directoryPath error:(NSError **)outError objectSerializer:(NSData *(^)(id))serializer
{
    NSString *objectsPath = [directoryPath stringByAppendingPathComponent:@"objects.archive"];

    //Write archive
    BOOL didWriteArchive = [self.class writeObjects:self.objectsByStorageRecords.allValues toPath:objectsPath objectSerializer:serializer error:outError];
    return didWriteArchive;


//    if (!didWriteArchive) return NO;
//
//    //Write index
//    NSError *error;
//    NSInteger previousVersion = -1;
//    NSString *previousIndexPath = [[self class] latestStorageRecordsPathInDirectoryAtPath:directoryPath version:&previousVersion error:&error];
//    NSString *indexFilename = [NSString stringWithFormat:@"%@.index", @((previousIndexPath == nil) ? 1 : previousVersion+1)];
//    NSString *indexPath = [directoryPath stringByAppendingPathComponent:indexFilename];
//
//    NSData *indexData = [NSKeyedArchiver archivedDataWithRootObject:self.objectsByStorageRecords.allKeys];
//    BOOL didWriteIndex = [indexData writeToFile:indexPath atomically:YES];
//
//    return didWriteIndex;
}



#pragma mark - Instance life cycle
-(instancetype)init
{
    return [self initWithObjectsByStorageRecords:[NSMutableDictionary new]];
}



-(instancetype)initWithObjectsByStorageRecords:(NSDictionary *)objectsByStorageRecords
{
    return [self initWithObjectsByStorageRecords:objectsByStorageRecords previousContainer:nil];
}



-(instancetype)initWithObjectsByStorageRecords:(NSDictionary *)objectsByStorageRecords previousContainer:(BCOObjectStorageContainer *)previousContainer
{
    NSParameterAssert(objectsByStorageRecords);

    self = [super init];
    if (self == nil) return nil;

    _objectsByStorageRecords = objectsByStorageRecords;

    return self;
}



#pragma mark - Random content access
-(id)objectForStorageRecord:(BCOStorageRecord *)record
{
    id object = self.objectsByStorageRecords[record];
    if (object != nil) {
        return (object == [NSNull null]) ? nil : object;
    }

    return [self.previousContainer objectForStorageRecord:record];
}



-(BCOStorageRecord *)storageRecordForObject:(id)object
{
    BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];

    id canonicalObject = self.objectsByStorageRecords[record];

    return (canonicalObject == nil) ? nil : record;
}



#pragma mark - BCOObjectStorageEnumerator
-(void)enumerateStorageRecordsUsingBlock:(void(^)(BCOStorageRecord *record, BOOL *stop))block
{
    [[[BCOObjectStorageEnumerator alloc] initWithStorageContainer:self records:nil] enumerateStorageRecordsUsingBlock:block];
}



-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block
{
    [[[BCOObjectStorageEnumerator alloc] initWithStorageContainer:self records:nil] enumerateStorageRecordsAndObjectsUsingBlock:block];
}



//Enumerated content access
-(id)storageRecordEnumeratorWithStorageRecords:(id<NSFastEnumeration>)records
{
    return [[BCOObjectStorageEnumerator alloc] initWithStorageContainer:self records:records];
}

@end





#pragma mark - BCOObjectStorageEnumerator

@implementation BCOObjectStorageEnumerator

-(instancetype)initWithStorageContainer:(BCOObjectStorageContainer *)storageContainer records:(id<NSFastEnumeration>)records
{
    NSParameterAssert(storageContainer);

    self = [super init];
    if (self == nil) return nil;

    _storageContainer = storageContainer;
    _records = records;

    return self;
}



-(void)enumerateStorageRecordsUsingBlock:(void(^)(BCOStorageRecord *record, BOOL *stop))block
{
    if (self.records != nil) {
        BOOL stop = NO;
        for (BCOStorageRecord *record in self.records) {
            block(record, &stop);
            if (stop) return;
        }
        return;
    }

    NSMutableSet *visitedRecords = [NSMutableSet new];
    BCOObjectStorageContainer *container = self.storageContainer;

    while (container != nil) {

        [container.objectsByStorageRecords enumerateKeysAndObjectsUsingBlock:^(BCOStorageRecord *record, id obj, BOOL *stop) {
            BOOL isVisited = [visitedRecords containsObject:record];
            if (isVisited) return;

            [visitedRecords addObject:record];

            if (obj != [NSNull null]) block(record, stop);
        }];

        container = container.previousContainer;
    }
}



-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block
{
    BCOObjectStorageContainer *container = self.storageContainer;

    [self enumerateStorageRecordsUsingBlock:^(BCOStorageRecord *record, BOOL *stop) {
        id object = [container objectForStorageRecord:record];
        block(record, object, stop);
    }];
}

@end





@implementation BCOObjectStorageContainerBuilder
{
    BCOObjectStorageContainer *_previousContainer;
    NSMutableDictionary *_objectsByStorageRecords;
}



#pragma mark - Instance life cycle
+(instancetype)builderWithPreviousStorageContainer:(BCOObjectStorageContainer *)previousContainer
{
    return [[self alloc] initWithPreviousStorageContainer:previousContainer];
}



-(instancetype)init
{
    return [self initWithPreviousStorageContainer:nil];
}



-(instancetype)initWithPreviousStorageContainer:(BCOObjectStorageContainer *)previousContainer
{
    self = [super init];
    if (self == nil) return nil;

    _previousContainer = previousContainer;
    _objectsByStorageRecords = [NSMutableDictionary new];

    return self;
}



#pragma mark -
-(BCOStorageRecord *)addObject:(id)object
{
    BCOStorageRecord *record = [BCOStorageRecord storageRecordForObject:object];
    _objectsByStorageRecords[record] = object;

    return record;
}



-(void)removeObjectForStorageRecord:(BCOStorageRecord *)storageRecord
{
    _objectsByStorageRecords[storageRecord] = [NSNull null];
}



-(BCOObjectStorageContainer *)finalize
{
    return [[BCOObjectStorageContainer alloc] initWithObjectsByStorageRecords:_objectsByStorageRecords previousContainer:_previousContainer];
}

@end
