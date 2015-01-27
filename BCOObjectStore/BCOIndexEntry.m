//
//  BCOIndexEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOIndexEntry.h"



@interface BCOIndexEntry ()
@property(nonatomic) id key;
@end



@implementation BCOIndexEntry

#pragma mark - instance life cylce
-(instancetype)init
{
    return [self initWithKey:nil objects:nil];
}


-(instancetype)initWithKey:(id)key objects:(NSSet *)objects
{
    return [self initWithKey:key objects:objects shouldCopyObjects:YES];
}


-(instancetype)initWithKey:(id)key objects:(NSSet *)objects shouldCopyObjects:(BOOL)shouldCopyObjects
{
    NSParameterAssert(key);

    self = [super init];
    if (self == nil) return nil;

    _key = key;
    _objects = (shouldCopyObjects) ? [objects copy] : objects;

    return self;
}



-(NSComparisonResult)compare:(BCOIndexEntry *)otherEntry
{
    return [self.key compare:otherEntry.key];
}



-(id)copyWithZone:(NSZone *)zone
{
    return ([self.class isEqual:BCOIndexEntry.class]) ? self : [[BCOIndexEntry alloc] initWithKey:self.key objects:self.objects];
}



-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[BCOMutableIndexEntry alloc] initWithKey:self.key objects:self.objects];
}

@end



@implementation BCOMutableIndexEntry

-(instancetype)initWithKey:(id)key objects:(NSSet *)objects
{
    return [super initWithKey:key objects:[objects mutableCopy] shouldCopyObjects:NO];
}

@end
