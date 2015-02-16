//
//  BCOQueryCatalogEntry.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import "BCOQueryCatalogEntry.h"
#import "BCOIndexValue.h"



@implementation BCOQueryCatalogEntry

-(instancetype)initWithReference:(id)reference indexValuesByIndexName:(NSDictionary *)indexValuesByIndexName
{
    NSParameterAssert(reference);
    self = [super init];
    if (self == nil) return nil;

    _reference = reference;
    _indexValuesByIndexName = [indexValuesByIndexName copy];

    return self;
}

@end
