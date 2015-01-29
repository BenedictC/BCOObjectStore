//
//  BCOStorageRecordToIndexReferencesLookUpTable.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;



@interface BCOStorageRecordToIndexReferencesLookUpTable : NSObject <NSCopying>

-(void)addIndexReferenceWithIndexName:(NSString *)indexName indexKey:(NSString *)indexKey forStorageRecord:(BCOStorageRecord *)storageRecord;
-(void)removeIndexReferencesForStorageRecord:(BCOStorageRecord *)storageRecord;

-(void)enumerateIndexReferencesForStorageRecord:(BCOStorageRecord *)storageRecord usingBlock:(void(^)(NSString *indexName, NSString *indexKey))block;

@end
