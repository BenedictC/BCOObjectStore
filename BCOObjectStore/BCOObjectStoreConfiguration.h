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

+(id(^)(NSData *))defaultObjectDeserializer;
+(NSData *(^)(id))defaultObjectSerializer;

@property(nonatomic) dispatch_queue_t dispatchQueue;

@property(nonatomic, copy) NSString *persistentStorePath;
@property(nonatomic, copy) id (^objectDeserializer)(NSData * archive);
@property(nonatomic, copy) NSData *(^objectSerializer)(id object);

@property(nonatomic, readonly) NSDictionary *indexDescriptions;

-(void)addIndexWithName:(NSString *)indexName indexValueGenerator:(BCOIndexValueGenerator)generator valueComparator:(NSComparator)comparator;

@end

