//
//  BCOStorageRecord.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecord.h"



@interface BCOStorageRecord ()
@property(nonatomic, readonly) id value;
@end



@implementation BCOStorageRecord

+(BCOStorageRecord *)storageRecordForObject:(id)object
{
    BOOL isSerializable = NO; //TODO:
    if (isSerializable) {
#pragma message "TODO: We need to change `object` to be a value that we can reliable derive from `object` so that we can\
lookup match up an object inserted into the store with on that already exists in the store but only on disk and that hasn't been loaded from disk. \
This cannot be based on -hash because that may rely on a pointer which will change from on each run. \
A murmur3 hash of the data represention of the object seems like a good start."

    }

    return [[BCOStorageRecord alloc] initWithValue:object];
}



#pragma mark - instance life cycle
-(instancetype)initWithValue:(id)value
{
    self = [super init];
    if (self == nil) return nil;
    _value = value;
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
