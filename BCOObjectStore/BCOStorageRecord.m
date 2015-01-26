//
//  BCOStorageRecord.m
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOStorageRecord.h"



@interface BCOStorageRecord ()
@property(nonatomic, readonly) id object;
@end



@implementation BCOStorageRecord

#pragma mark - instance life cycle
-(instancetype)initWithObject:(id)object
{
    self = [super init];
    if (self == nil) return nil;
    _object = object;
    return self;
}



-(id)copyWithZone:(NSZone *)zone
{
    return self;
}



#pragma mark - equality
-(NSComparisonResult)compare:(BCOStorageRecord *)otherKey
{
    uintptr_t obj = (uintptr_t)_object;
    uintptr_t otherObj = (uintptr_t)otherKey->_object;

    if (otherObj > obj) return NSOrderedAscending;
    if (otherObj < obj) return NSOrderedDescending;

    return NSOrderedSame;
}



-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:BCOStorageRecord.class]) return NO;

    BCOStorageRecord *otherToken = object;

    return [self.object isEqual:otherToken.object];
}



-(NSUInteger)hash
{
    return [self.object hash];
}



+(NSComparator)storageRecordComparator
{
    static NSComparisonResult (^ const comparator)(BCOStorageRecord *, BCOStorageRecord *) = ^NSComparisonResult(BCOStorageRecord *record1, BCOStorageRecord *record2) {
        return [record1 compare:record2];
    };

    return comparator;
}

@end
