//
//  BCOObjectStoreConfiguration.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>

#import "BCOColumnKey.h"
@class BCOIndexColumnDescription;



@interface BCOObjectStoreConfiguration : NSObject <NSCopying>

@property(nonatomic) dispatch_queue_t dispatchQueue;
@property(nonatomic) NSData *initialSnapshotArchive;

-(void)addIndexWithName:(NSString *)indexName keyGenerator:(BCOColumnKeyGenerator)keyGenerator keyComparator:(NSComparator)comparator;
-(void)addIndexWithName:(NSString *)indexName indexColumnDescription:(BCOIndexColumnDescription *)indexColumnDescription;

@property(nonatomic, readonly) NSDictionary *indexColumnDescriptions;

@end

