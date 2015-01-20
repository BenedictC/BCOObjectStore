//
//  BCOIndex.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 20/01/2015.
//
//

#import "BCOIndex.h"
#import "BCOIndexDescription.h"



@interface BCOIndex ()
@property(readonly) NSDictionary *objectsByKey;
@end



@implementation BCOIndex

-(instancetype)initWithObjects:(NSSet *)objects indexDescription:(BCOIndexDescription *)indexDescription
{
    NSParameterAssert(objects);
    NSParameterAssert(indexDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexDescription = indexDescription;

    NSMutableDictionary *objectsByKey = [NSMutableDictionary new];
    BCOIndexer indexer = indexDescription.indexer;
    for (id value in objects) {
        id key = indexer(value);
        if (key != nil) {
            NSMutableSet *bucket = objectsByKey[key];
            if (bucket == nil) {
                bucket = [NSMutableSet new];
                objectsByKey[key] = bucket;
            }

            [bucket addObject:value];
        }
    }
    _objectsByKey = objectsByKey;

    return self;
}



-(NSSet *)objectsForKey:(id)key
{
    NSSet *objects = self.objectsByKey[key];
    return (objects == nil) ? [NSSet set] : objects;
}

@end
