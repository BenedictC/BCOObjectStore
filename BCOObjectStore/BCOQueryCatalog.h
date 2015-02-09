//
//  BCOQueryCatalog.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 29/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOQueryCatalogEntry;



@protocol BCOQueryCatalogBuilder <NSObject, NSCopying>

-(BCOQueryCatalogEntry *)addEntryForRecord:(id)record byIndexingObject:(id)object;
-(void)removeEntry:(BCOQueryCatalogEntry *)entry;

@end



@interface BCOQueryCatalog : NSObject <BCOQueryCatalogBuilder>

-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions;

@property(nonatomic, readonly) NSDictionary *indexDescriptions;

-(NSSet *)recordsInIndex:(NSString *)indexName forValue:(id)value;
-(NSSet *)recordsInIndex:(NSString *)indexName forValuesNotEqualToValue:(id)value;

-(NSSet *)recordsInIndex:(NSString *)indexName forValuesInSet:(NSArray *)value;
-(NSSet *)recordsInIndex:(NSString *)indexName forValuesNotInSet:(NSArray *)value;

-(NSSet *)recordsInIndex:(NSString *)indexName lessThanValue:(id)value;
-(NSSet *)recordsInIndex:(NSString *)indexName lessThanOrEqualToValue:(id)value;
-(NSSet *)recordsInIndex:(NSString *)indexName greaterThanValue:(id)value;
-(NSSet *)recordsInIndex:(NSString *)indexName greaterThanOrEqualToValue:(id)value;


@end
