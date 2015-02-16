//
//  BCOIndexEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOIndexEntry.h"



@interface BCOIndexEntry ()
{
    @protected
    NSSet *_references;
}
@property(nonatomic) id indexValue;
@end



@implementation BCOIndexEntry

#pragma mark - instance life cylce
-(instancetype)init
{
    return [self initWithIndexValue:nil references:nil];
}


-(instancetype)initWithIndexValue:(id)value references:(NSSet *)references
{
    return [self initWithIndexValue:value references:references shouldCopyObjects:YES];
}


-(instancetype)initWithIndexValue:(id)value references:(NSSet *)references shouldCopyObjects:(BOOL)shouldCopyReferences
{
    NSParameterAssert(value);

    self = [super init];
    if (self == nil) return nil;

    _indexValue = value;
    _references = (shouldCopyReferences) ? [references copy] : references;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    BOOL isImmutable = [self.class isEqual:BCOIndexEntry.class];
    return (isImmutable) ? self : [[BCOIndexEntry alloc] initWithIndexValue:self.indexValue references:self.references];
}



-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[BCOMutableIndexEntry alloc] initWithIndexValue:self.indexValue references:self.references];
}



#pragma mark - equality
-(BOOL)isEqual:(BCOIndexEntry *)object
{
    if (![object isKindOfClass:BCOIndexEntry.class]) return NO;

    return [object.indexValue isEqual:self.indexValue];
}



-(NSUInteger)hash
{
    return BCOIndexEntry.class.hash ^ [self.indexValue hash];
}



#pragma mark - properties
-(NSSet *)references
{
    //Note that we return a copy because of the mutable subclass
    return [_references copy];
}



-(NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"<%@: %p> {value: %@}", NSStringFromClass(self.class), self, self.indexValue];
    return description;
}

@end



@implementation BCOMutableIndexEntry

-(instancetype)initWithIndexValue:(id)value references:(NSSet *)references
{
    NSMutableSet *mutableReferences = (references == nil) ? [NSMutableSet new] : [references mutableCopy];
    return [super initWithIndexValue:value references:mutableReferences shouldCopyObjects:NO];
}



-(NSMutableSet *)mutableReferences
{
    id references = _references;
    NSAssert([references isKindOfClass:NSMutableSet.class], @"BCOMutableIndexEntry.references is expected to be an NSMutableSet but is a %@.", NSStringFromClass([references class]));
    return references;
}



-(void)addReference:(id)reference
{
    [self.mutableReferences addObject:reference];
}



-(void)removeReference:(id)reference
{
    [self.mutableReferences removeObject:reference];
}

@end
