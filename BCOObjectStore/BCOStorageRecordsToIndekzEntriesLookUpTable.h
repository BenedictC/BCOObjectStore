//
//  BCOStorageRecordToIndekzReferencesLookUpTable.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;
@class BCOIndekzEntry;



@interface BCOStorageRecordsToIndekzEntriesLookUpTable : NSObject <NSCopying>

-(void)setIndekzEntry:(BCOIndekzEntry *)indekzEntry forStorageRecord:(BCOStorageRecord *)storageRecord;

-(BCOIndekzEntry *)indekzEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

-(void)removeIndekzEntryForStorageRecord:(BCOStorageRecord *)storageRecord;

@end
