//
//  BCOStorageRecordsToQueryCatalogEntriesLookUpTable.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;
@class BCOQueryCatalogEntry;



@interface BCOStorageRecordsToQueryCatalogEntriesLookUpTable : NSObject <NSCopying>

-(void)setQueryCatalogEntry:(BCOQueryCatalogEntry *)queryCatalogEntry forStorageRecord:(BCOStorageRecord *)storageRecord;

-(BCOQueryCatalogEntry *)queryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

-(void)removeQueryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

@end
