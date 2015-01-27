//
//  BCOIndexEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOIndexEntry.h"



NSComparisonResult (^ const BCOIndexEntryComparator)(BCOIndexEntry *entry1, BCOIndexEntry *entry2) = ^NSComparisonResult(BCOIndexEntry *entry1, BCOIndexEntry *entry2) {
    return [entry1 compare:entry2];
};



@interface BCOIndexEntry ()
@property(nonatomic) id key;
@end



@implementation BCOIndexEntry

#pragma mark - instance life cylce
-(instancetype)initWithKey:(id)key
{
    return [self initWithKey:key objects:[NSSet set]];
}



-(instancetype)initWithKey:(id)key objects:(NSSet *)objects
{
    NSParameterAssert(key);
    NSParameterAssert(objects);

    self = [super init];
    if (self == nil) return nil;

    _key = key;
    _objects = [objects mutableCopy];

    return self;
}



-(NSComparisonResult)compare:(BCOIndexEntry *)otherEntry
{
    return [self.key compare:otherEntry.key];
}



-(id)copyWithZone:(NSZone *)zone
{
    return [[BCOIndexEntry alloc] initWithKey:self.key objects:self.objects];
}

@end



@implementation BCOIndexReferenceEntry
@end
