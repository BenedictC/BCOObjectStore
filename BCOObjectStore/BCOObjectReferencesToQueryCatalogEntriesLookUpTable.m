//
//  BCOObjectReferencesToQueryCatalogEntriesLookUpTable.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOObjectReferencesToQueryCatalogEntriesLookUpTable.h"
#import "BCOQueryCatalogEntry.h"
#import "BCOObjectReference.h"



@interface BCOObjectReferencesToQueryCatalogEntriesLookUpTable ()
{
    NSDictionary *_queryCatalogEntriesByObjectReferences;
    NSMutableDictionary *_mutableQueryCatalogEntriesByObjectReferences;
}

@end



@implementation BCOObjectReferencesToQueryCatalogEntriesLookUpTable

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithQueryCatalogEntriesByObjectReferences:[NSMutableDictionary new]];
}



-(instancetype)initWithQueryCatalogEntriesByObjectReferences:(NSDictionary *)queryCatalogEntriesByObjectReferences
{
    self = [super init];
    if (self == nil) return nil;

    _queryCatalogEntriesByObjectReferences = queryCatalogEntriesByObjectReferences;

    return self;
}



#pragma mark - copying
-(id)copyWithZone:(NSZone *)zone
{
    NSDictionary *entries = ([self isQueryCatalogEntriesByObjectReferencesDirty]) ? [self.queryCatalogEntriesByObjectReferences copy] : self.queryCatalogEntriesByObjectReferences;

    return  [[BCOObjectReferencesToQueryCatalogEntriesLookUpTable alloc] initWithQueryCatalogEntriesByObjectReferences:entries];
}



#pragma mark - properties
-(BOOL)isQueryCatalogEntriesByObjectReferencesDirty
{
    return (_mutableQueryCatalogEntriesByObjectReferences != nil);
}



-(NSDictionary *)queryCatalogEntriesByObjectReferences
{
    return ([self isQueryCatalogEntriesByObjectReferencesDirty]) ? _mutableQueryCatalogEntriesByObjectReferences : _queryCatalogEntriesByObjectReferences;
}



-(NSMutableDictionary *)mutableQueryCatalogEntriesByObjectReferences
{
    if (_mutableQueryCatalogEntriesByObjectReferences != nil) return _mutableQueryCatalogEntriesByObjectReferences;

    _mutableQueryCatalogEntriesByObjectReferences  = [_queryCatalogEntriesByObjectReferences mutableCopy];
    _queryCatalogEntriesByObjectReferences = nil;

    return _mutableQueryCatalogEntriesByObjectReferences;
}



#pragma mark - object access
-(void)setQueryCatalogEntry:(id)queryCatalogEntry forObjectReference:(BCOObjectReference *)objectReference
{
    self.mutableQueryCatalogEntriesByObjectReferences[objectReference] = queryCatalogEntry;
}



-(BCOQueryCatalogEntry *)queryCatalogEntryForObjectReference:(BCOObjectReference *)objectReference
{
    return self.queryCatalogEntriesByObjectReferences[objectReference];
}



-(void)removeQueryCatalogEntryForObjectReference:(BCOObjectReference *)objectReference
{
    [self.mutableQueryCatalogEntriesByObjectReferences removeObjectForKey:objectReference];
}

@end
