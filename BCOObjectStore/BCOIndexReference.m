//
//  BCOIndexReference.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOIndexReference.h"



@implementation BCOIndexReference;

-(instancetype)initWithIndexName:(NSString *)indexName key:(id)key
{
    self = [super init];
    if (self == nil) return nil;

    _indexName = [indexName copy];
    _key = key;

    return self;
}



-(NSUInteger)hash
{
    return self.class.hash ^ self.indexName.hash ^ [self.key hash];
}



-(BOOL)isEqual:(id)object
{
    if (self == object) return YES;

    if (![[object class] isEqual:BCOIndexReference.class]) return NO;

    return [object hash] == self.hash;
}



-(id)copyWithZone:(NSZone *)zone
{
    return self;
}

@end
