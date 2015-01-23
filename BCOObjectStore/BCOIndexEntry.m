//
//  BCOIndexEntry.m
//  Pods
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
    self = [super init];
    if (self == nil) return nil;

    _objects = [NSMutableSet set];
    _key = key;

    return self;
}



-(NSComparisonResult)compare:(BCOIndexEntry *)otherEntry
{
    return [self.key compare:otherEntry.key];
}



-(id)copyWithZone:(NSZone *)zone
{
    BCOIndexEntry *entry = [[BCOIndexEntry alloc] initWithKey:self.key];
    [entry.objects unionSet:self.objects];

    return entry;
}

@end



@implementation BCOIndexReferenceEntry
@end
