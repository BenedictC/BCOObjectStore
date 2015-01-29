//
//  BCOIndexEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOColumnEntry.h"



@interface BCOColumnEntry ()
@property(nonatomic) id<BCOColumnValue> value;
@end



@implementation BCOColumnEntry

#pragma mark - instance life cylce
-(instancetype)init
{
    return [self initWithValue:nil objects:nil];
}


-(instancetype)initWithValue:(id)value objects:(NSSet *)objects
{
    return [self initWithvalue:value objects:objects shouldCopyObjects:YES];
}


-(instancetype)initWithvalue:(id)value objects:(NSSet *)objects shouldCopyObjects:(BOOL)shouldCopyObjects
{
    NSParameterAssert(value);

    self = [super init];
    if (self == nil) return nil;

    _value = value;
    _objects = (shouldCopyObjects) ? [objects copy] : objects;

    return self;
}



-(NSComparisonResult)compare:(BCOColumnEntry *)otherEntry
{
    return [self.value compare:otherEntry.value];
}



-(id)copyWithZone:(NSZone *)zone
{
    return ([self.class isEqual:BCOColumnEntry.class]) ? self : [[BCOColumnEntry alloc] initWithValue:self.value objects:self.objects];
}



-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[BCOMutableIndexEntry alloc] initWithValue:self.value objects:self.objects];
}

@end



@implementation BCOMutableIndexEntry

-(instancetype)initWithValue:(id)value objects:(NSSet *)objects
{
    return [super initWithvalue:value objects:[objects mutableCopy] shouldCopyObjects:NO];
}

@end
