//
//  BCOObjectStore.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStore.h"
#import "BCOIndexDescription.h"



#pragma mark - BCOObjectStoreIndex
@interface BCOObjectStoreIndex : NSObject
@property(readonly) BCOIndexDescription *indexDescription;
@property(readonly) NSMutableDictionary *objectsByUniqueID;
@end



@implementation BCOObjectStoreIndex

-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription
{
    NSParameterAssert(indexDescription);

    self = [super init];
    if (self == nil) return nil;

    _indexDescription = indexDescription;
    _objectsByUniqueID = [NSMutableDictionary new];

    return self;
}



-(void)addObject:(id)object
{
    id key = [object valueForKeyPath:self.indexDescription.valueKeyPath];
    self.objectsByUniqueID[key] = object;
}



-(NSDictionary *)allObjects
{
    return self.objectsByUniqueID;
}



-(id)objectForUniqueID:(id)uniqueID
{
    return self.objectsByUniqueID[uniqueID];
}

@end





#pragma mark - BCOObjectStore
@interface BCOObjectStore ()

@property(readonly) NSDictionary *indexesByObjectClassName;

@end



@implementation BCOObjectStore

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSSet *)indexDescriptions
{
    self = [super init];
    if (self == nil) return nil;

    _objects = [objects copy];
    _indexDescriptions = [indexDescriptions copy];

    //Build indexesByObjectClassName
    NSMutableDictionary *indexesByObjectClassName = [NSMutableDictionary new];
    for (BCOIndexDescription *indexDescription in indexDescriptions) {
        NSString *className = NSStringFromClass(indexDescription.indexedClass);
        BCOObjectStoreIndex *index = [[BCOObjectStoreIndex alloc] initWithIndexDescription:indexDescription];
        indexesByObjectClassName[className] = index;
    }

    //Add the objects to the indexes
    for (id object in objects) {
        NSString *className = NSStringFromClass([object class]);
        BCOObjectStoreIndex *index = indexesByObjectClassName[className];

        [index addObject:object];
    }
    //Store the indexes
    _indexesByObjectClassName = indexesByObjectClassName;

    return self;
}



-(NSDictionary *)fetchObjectsOfClass:(Class)indexedClass
{
    BCOObjectStoreIndex *index = self.indexesByObjectClassName[NSStringFromClass(indexedClass)];
    return [index allObjects];
}



-(id)fetchObjectOfClass:(Class)indexedClass uniqueID:(id)uniqueID
{
    BCOObjectStoreIndex *index = self.indexesByObjectClassName[NSStringFromClass(indexedClass)];
    return [index objectForUniqueID:uniqueID];
}

@end
