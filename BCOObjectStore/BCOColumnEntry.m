//
//  BCOColumnEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOColumnEntry.h"



@interface BCOColumnEntry ()
{
    @protected
    NSSet *_records;
}
@property(nonatomic) id value;
@end



@implementation BCOColumnEntry

#pragma mark - instance life cylce
-(instancetype)init
{
    return [self initWithValue:nil records:nil];
}


-(instancetype)initWithValue:(id)value records:(NSSet *)records
{
    return [self initWithvalue:value records:records shouldCopyObjects:YES];
}


-(instancetype)initWithvalue:(id)value records:(NSSet *)records shouldCopyObjects:(BOOL)shouldCopyRecords
{
    NSParameterAssert(value);

    self = [super init];
    if (self == nil) return nil;

    _value = value;
    _records = (shouldCopyRecords) ? [records copy] : records;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    return ([self.class isEqual:BCOColumnEntry.class]) ? self : [[BCOColumnEntry alloc] initWithValue:self.value records:self.records];
}



-(id)mutableCopyWithZone:(NSZone *)zone
{
    return [[BCOMutableColumnEntry alloc] initWithValue:self.value records:self.records];
}



#pragma mark - equality
-(BOOL)isEqual:(BCOColumnEntry *)object
{
    if (![object isKindOfClass:BCOColumnEntry.class])  return NO;

    return [[object value] isEqual:self.value];
}



-(NSUInteger)hash
{
    return BCOColumnEntry.class.hash ^ [self.value hash];
}



#pragma mark - properties
-(NSSet *)records
{
    //Note that we return a copy because of the mutable subclass
    return [_records copy];
}



-(NSString *)description
{
    NSString *description = [NSString stringWithFormat:@"<%@: %p> {value: %@}", NSStringFromClass(self.class), self, self.value];
    return description;
}

@end



@implementation BCOMutableColumnEntry

-(instancetype)initWithValue:(id)value records:(NSSet *)records
{
    return [super initWithvalue:value records:[records mutableCopy] shouldCopyObjects:NO];
}



-(NSMutableSet *)mutableRecords
{
    id records = _records;
    NSAssert([records isKindOfClass:NSMutableSet.class], @".records is expected to be an NSMutableSet but is a %@.", NSStringFromClass([records class]));
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
