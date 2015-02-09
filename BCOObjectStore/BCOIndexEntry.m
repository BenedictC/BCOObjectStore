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
    NSSet *_records;
}
@property(nonatomic) id indexValue;
@end



@implementation BCOIndexEntry

#pragma mark - instance life cylce
-(instancetype)init
{
    return [self initWithIndexValue:nil records:nil];
}


-(instancetype)initWithIndexValue:(id)value records:(NSSet *)records
{
    return [self initWithIndexValue:value records:records shouldCopyObjects:YES];
}


-(instancetype)initWithIndexValue:(id)value records:(NSSet *)records shouldCopyObjects:(BOOL)shouldCopyRecords
{
    NSParameterAssert(value);

    self = [super init];
    if (self == nil) return nil;

    _indexValue = value;
    _records = (shouldCopyRecords) ? [records copy] : records;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    BOOL isImmutable = [self.class isEqual:BCOIndexEntry.class];
    return (isImmutable) ? self : [[BCOIndexEntry alloc] initWithIndexValue:self.indexValue records:self.records];
}



-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[BCOMutableIndexEntry alloc] initWithIndexValue:self.indexValue records:self.records];
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
-(NSSet *)records
{
    //Note that we return a copy because of the mutable subclass
    return [_records copy];
}



-(NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"<%@: %p> {value: %@}", NSStringFromClass(self.class), self, self.indexValue];
    return description;
}

@end



@implementation BCOMutableIndexEntry

-(instancetype)initWithIndexValue:(id)value records:(NSSet *)records
{
    NSMutableSet *mutableRecords = (records == nil) ? [NSMutableSet new] : [records mutableCopy];
    return [super initWithIndexValue:value records:mutableRecords shouldCopyObjects:NO];
}



-(NSMutableSet *)mutableRecords
{
    id records = _records;
    NSAssert([records isKindOfClass:NSMutableSet.class], @"BCOMutableIndexEntry.records is expected to be an NSMutableSet but is a %@.", NSStringFromClass([records class]));
    return records;
}



-(void)addRecord:(id)record
{
    [self.mutableRecords addObject:record];
}



-(void)removeRecord:(id)record
{
    [self.mutableRecords removeObject:record];
}

@end
