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

-(instancetype)initWithRecord:(id)record indexValuesByIndexName:(NSDictionary *)indexValuesByIndexName
{
    NSParameterAssert(record);
    self = [super init];
    if (self == nil) return nil;

    _record = record;
    _indexValuesByIndexName = [indexValuesByIndexName copy];

    return self;
}

@end
