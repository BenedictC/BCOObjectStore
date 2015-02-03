//
//  BCOObjectStoreConfiguration.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>

#import "BCOColumnValue.h"
@class BCOColumnDescription;



@interface BCOObjectStoreConfiguration : NSObject <NSCopying>

@property(nonatomic) dispatch_queue_t dispatchQueue;

@property(nonatomic, copy) NSString *persistentStorePath;

@property(nonatomic, readonly) NSDictionary *columnDescriptions;

-(void)addColumnWithName:(NSString *)columnName columnValueGenerator:(BCOColumnValueGenerator)generator valueComparator:(NSComparator)comparator;
-(void)addColumnWithName:(NSString *)columnName columnDescription:(BCOColumnDescription *)columnDescription;

@end

