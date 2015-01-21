//
//  BCOIndex.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 20/01/2015.
//
//

#import "BCOIndex.h"
#import "BCOIndexDescription.h"



@interface BCOIndexReference : NSObject
@property(nonatomic) NSString *indexName;
@property(nonatomic) NSString *key;
@end

@implementation BCOIndexReference;

@end



@interface BCOIndex ()
@property(readonly) NSDictionary *indexesByIndexName;
@property(readonly) NSMapTable *referenceSetsByObject;
@end



@implementation BCOIndex

-(instancetype)init
{
    return [self initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
}



-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions
{
    NSParameterAssert(objects);
    NSParameterAssert(indexDescriptions);

    self = [super init];
    if (self == nil) return nil;

    //Store ivars
    _indexDescriptions = [indexDescriptions copy];

    //Build index
    NSMutableDictionary *indexesByIndexName = [NSMutableDictionary new];
    NSMapTable *referenceSetsByObject = [NSMapTable strongToStrongObjectsMapTable];
    [indexDescriptions enumerateKeysAndObjectsUsingBlock:^(NSString *indexName, BCOIndexDescription *indexDescription, BOOL *stop) {
        //Create and add the index
        NSMutableDictionary *index = [NSMutableDictionary new];
        indexesByIndexName[indexName] = index;

        //Add each object to the index
        BCOIndexer indexer = indexDescription.indexer;
        for (id object in objects) {
            id key = indexer(object);
            if (key == nil) continue;

            //Fetch/create the bucket to store the object in
            NSMutableSet *objectsBucket = index[key];
            if (objectsBucket == nil) {
                objectsBucket = [NSMutableSet new];
                index[key] = objectsBucket;
            }

            //Store the object
            [objectsBucket addObject:object];

            //Create indexReference
            BCOIndexReference *reference = [BCOIndexReference new];
            reference.indexName = indexName;
            reference.key = key;

            NSMutableSet *referenceSet = [referenceSetsByObject objectForKey:object];
            if (referenceSet == nil) {
                referenceSet = [NSMutableSet new];
                [referenceSetsByObject setObject:referenceSet forKey:object];
            }
            [referenceSet addObject:reference];
        }
    }];
    _indexesByIndexName = indexesByIndexName;
    _referenceSetsByObject = referenceSetsByObject;

    return self;
}



-(NSSet *)objectsForKey:(id)key inIndexNamed:(NSString *)indexName
{
    NSDictionary *index = self.indexesByIndexName[indexName];

    NSSet *objects = index[key];

    return (objects == nil) ? [NSSet set] : objects;
}

@end
