//
//  BCOObjectStoreConfiguration.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>

#import "BCOIndexValue.h"
@class BCOIndexDescription;



@interface BCOObjectStoreConfiguration : NSObject <NSCopying>

@property(nonatomic) dispatch_queue_t dispatchQueue;

@property(nonatomic, copy) NSString *persistentStorePath;

@property(nonatomic, readonly) NSDictionary *indexDescriptions;

-(void)addIndexWithName:(NSString *)indexName indexValueGenerator:(BCOIndexValueGenerator)generator valueComparator:(NSComparator)comparator;
-(void)addIndexWithName:(NSString *)indexName indexDescription:(BCOIndexDescription *)indexDescription;

@end

