//
//  BCOIndexReferencesLookUpTable.h
//  Pods
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;



@interface BCOIndexReferencesLookUpTable : NSObject <NSCopying>

-(void)addIndexReferenceWithIndexName:(NSString *)indexName indexKey:(NSString *)indexKey forStorageRecord:(BCOStorageRecord *)storageRecord;
-(void)enumerateIndexReferencesForStorageRecord:(BCOStorageRecord *)storageRecord usingBlock:(void(^)(NSString *indexName, NSString *indexKey))block;

-(void)removeIndexReferencesForStorageRecord:(BCOStorageRecord *)storageRecord;

@end
