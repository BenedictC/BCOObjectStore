//
//  BCOStorageRecordToIndexReferencesLookUpTable.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;
@class BCOIndexEntry;



@interface BCOStorageRecordsToIndexEntriesLookUpTable : NSObject <NSCopying>

-(void)setIndexEntry:(BCOIndexEntry *)indexEntry forStorageRecord:(BCOStorageRecord *)storageRecord;

-(BCOIndexEntry *)indexEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

-(void)removeIndexEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

@end
