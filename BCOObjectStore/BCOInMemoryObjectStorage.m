//
//  BCOInMemoryObjectStorage.m
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOInMemoryObjectStorage.h"



@interface BCOObjectStorageLookUpToken () <NSCopying>
@property(nonatomic, readonly) id object;
@end



@implementation BCOObjectStorageLookUpToken

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
-(NSComparisonResult)compare:(BCOObjectStorageLookUpToken *)otherKey
{
    uintptr_t obj = (uintptr_t)_object;
    uintptr_t otherObj = (uintptr_t)otherKey->_object;

    if (otherObj > obj) return NSOrderedAscending;
    if (otherObj < obj) return NSOrderedDescending;

    return NSOrderedSame;
}



-(BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:BCOObjectStorageLookUpToken.class]) return NO;

    BCOObjectStorageLookUpToken *otherToken = object;

    return [self.object isEqual:otherToken.object];
}



-(NSUInteger)hash
{
    return [self.object hash];
}

@end



NSComparisonResult (^ const BCOObjectStorageLookUpTokenComparator)(BCOObjectStorageLookUpToken *entry1, BCOObjectStorageLookUpToken *entry2) = ^NSComparisonResult(BCOObjectStorageLookUpToken *entry1, BCOObjectStorageLookUpToken *entry2) {
    return [entry1 compare:entry2];
};





@interface BCOInMemoryObjectStorage ()
@property(nonatomic, readonly) NSMutableDictionary *objectsByTokens;
@end



@implementation BCOInMemoryObjectStorage

#pragma mark - instance life cycle
+(BCOInMemoryObjectStorage *)objectStorageWithObjects:(NSSet *)objects
{
    NSMutableDictionary *objectsByToken = [NSMutableDictionary new];
    for (id object in objects) {
        BCOObjectStorageLookUpToken *token = [[BCOObjectStorageLookUpToken alloc] initWithObject:object];
        objectsByToken[token] = object;
    }

    return [[BCOInMemoryObjectStorage alloc] initWithObjectsByTokens:objectsByToken];
}



-(instancetype)init
{
    return [self initWithObjectsByTokens:@{}];
}



-(instancetype)initWithObjectsByTokens:(NSDictionary *)objectsByTokens
{
    NSParameterAssert(objectsByTokens);

    self = [super init];
    if (self == nil) return nil;

    _objectsByTokens = [objectsByTokens mutableCopy];

    return self;
}



-(id)copyWithZone:(NSZone *)zone
{
    return [[BCOInMemoryObjectStorage alloc] initWithObjectsByTokens:self.objectsByTokens];
}



#pragma mark - content managment
-(BCOObjectStorageLookUpToken *)addObject:(id)object
{
    BCOObjectStorageLookUpToken *token = [[BCOObjectStorageLookUpToken alloc] initWithObject:object];
    _objectsByTokens[token] = object;
    return token;
}



-(void)removeObject:(id)object
{
    BCOObjectStorageLookUpToken *token = [self lookupTokenForObject:object];
    [_objectsByTokens removeObjectForKey:token];
}



-(id)objectForLookUpToken:(BCOObjectStorageLookUpToken *)token
{
    return _objectsByTokens[token];
}



-(BCOObjectStorageLookUpToken *)lookupTokenForObject:(id)object
{
    BCOObjectStorageLookUpToken *token = [[BCOObjectStorageLookUpToken alloc] initWithObject:object];

    id canonicalObject = _objectsByTokens[token];

    return (canonicalObject == nil) ? nil : token;
}



-(void)removeObjectForLookUpToken:(BCOObjectStorageLookUpToken *)lookUpToken
{
    [_objectsByTokens removeObjectForKey:lookUpToken];
}



-(NSSet *)allObjects
{
    return [NSSet setWithArray:self.objectsByTokens.allValues];
}



-(NSSet *)allTokens
{
    return [NSSet setWithArray:self.objectsByTokens.allKeys];
}

@end
