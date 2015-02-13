//
//  BCOStorageRecord.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecord.h"
#import <CommonCrypto/CommonCrypto.h>



@interface BCOStorageRecord ()
@property(nonatomic, readonly) id value;
@end



@implementation BCOStorageRecord

#pragma mark - instance life cycle
+(NSString *)md5HashForData:(NSData *)data
{
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];

    // Create 16 byte MD5 hash value, store in buffer
    CC_LONG length = (CC_LONG)data.length;
    CC_MD5(data.bytes, length, md5Buffer);

    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x",md5Buffer[i]];
    }

    return output;
}



+(BCOStorageRecord *)storageRecordForObject:(id)object
{
    BOOL isSerializable = NO; //TODO:
    if (isSerializable) {
        //TODO: We need a fingerprint for the data so that we store it on disk. We're currently using MD5 but that's a bad choice.
        //It would be much better to use Rabin Fingerprint function but we'd have to implement that from scratch.
        //Once we have the hash then we can store the object on disk.
    }

    NSData *archive = [NSKeyedArchiver archivedDataWithRootObject:object];
    NSString *md5 = [BCOStorageRecord md5HashForData:archive];

    return [[BCOStorageRecord alloc] initWithValue:md5];
}



-(instancetype)initWithValue:(id)value
{
    self = [super init];
    if (self == nil) return nil;
    _value = value;
    return self;
}



#pragma mark - NSArchiving
-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.value forKey:@"value"];
}



-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self == nil) return nil;

    _value = [aDecoder decodeObjectForKey:@"value"];

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    return self;
}



#pragma mark - equality
-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:BCOStorageRecord.class]) return NO;

    BCOStorageRecord *otherRecord = object;

    return [self.value isEqual:otherRecord.value];
}



-(NSUInteger)hash
{
    return [self.value hash];
}

@end
