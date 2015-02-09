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



@protocol BCOStorageRecordsToQueryCatalogEntriesLookUpTableBuilder <NSObject, NSCopying>

-(void)setQueryCatalogEntry:(BCOQueryCatalogEntry *)queryCatalogEntry forStorageRecord:(BCOStorageRecord *)storageRecord;
-(void)removeQueryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

@end



@interface BCOStorageRecordsToQueryCatalogEntriesLookUpTable : NSObject <BCOStorageRecordsToQueryCatalogEntriesLookUpTableBuilder>

-(BCOQueryCatalogEntry *)queryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

@end
