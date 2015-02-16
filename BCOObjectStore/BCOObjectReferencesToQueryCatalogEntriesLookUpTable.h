//
//  BCOObjectReferencesToQueryCatalogEntriesLookUpTable.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOObjectReference;
@class BCOQueryCatalogEntry;



@protocol BCOObjectReferencesToQueryCatalogEntriesLookUpTableBuilder <NSObject, NSCopying>

-(void)setQueryCatalogEntry:(BCOQueryCatalogEntry *)queryCatalogEntry forObjectReference:(BCOObjectReference *)objectReference;
-(void)removeQueryCatalogEntryForObjectReference:(BCOObjectReference *)objectReference;

@end



@interface BCOObjectReferencesToQueryCatalogEntriesLookUpTable : NSObject <BCOObjectReferencesToQueryCatalogEntriesLookUpTableBuilder>

-(BCOQueryCatalogEntry *)queryCatalogEntryForObjectReference:(BCOObjectReference *)objectReference;

@end
