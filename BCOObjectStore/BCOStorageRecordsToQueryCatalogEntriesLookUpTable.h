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



@interface BCOStorageRecordsToQueryCatalogEntriesLookUpTable : NSObject

-(BCOQueryCatalogEntry *)queryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

@end



@interface BCOStorageRecordsToQueryCatalogEntriesLookUpTableBuilder : NSObject

+(instancetype)builderWithPreviousTable:(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)table;

-(void)setQueryCatalogEntry:(BCOQueryCatalogEntry *)queryCatalogEntry forStorageRecord:(BCOStorageRecord *)storageRecord;
-(void)removeQueryCatalogEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

-(BCOStorageRecordsToQueryCatalogEntriesLookUpTable *)finalize;

@end
