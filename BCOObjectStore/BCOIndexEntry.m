//
//  BCOIndexEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOIndexEntry.h"
#import "BCOColumnKey.h"



@implementation BCOIndexEntry;

-(instancetype)initWithRecord:(id)record
{
    NSParameterAssert(record);
    self = [super init];
    if (self == nil) return nil;

    _record = record;
    _keysByColumnName = [NSMutableDictionary new];

    return self;
}

@end
