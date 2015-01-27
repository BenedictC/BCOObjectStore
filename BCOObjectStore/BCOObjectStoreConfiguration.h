//
//  BCOObjectStoreConfiguration.h
//  Pods
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>

#import "BCOKeyGenerator.h"
@class BCOIndexDescription;



@interface BCOObjectStoreConfiguration : NSObject <NSCopying>

@property(nonatomic) dispatch_queue_t dispatchQueue;
@property(nonatomic) NSData *initialSnapshotArchive;

-(void)addIndexWithName:(NSString *)indexName keyGenerator:(BCOKeyGenerator)keyGenerator keyComparator:(NSComparator)comparator;
-(void)addIndexWithName:(NSString *)indexName indexDescription:(BCOIndexDescription *)indexDescription;

@property(nonatomic, readonly) NSDictionary *indexDescriptions;

@end

