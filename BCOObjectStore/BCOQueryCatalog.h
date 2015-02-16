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

-(BCOQueryCatalogEntry *)addEntryForReference:(id)reference byIndexingObject:(id)object;
-(void)removeEntry:(BCOQueryCatalogEntry *)entry;

@end



@interface BCOQueryCatalog : NSObject <BCOQueryCatalogBuilder>

-(instancetype)initWithIndexDescriptions:(NSDictionary *)indexDescriptions;

@property(nonatomic, readonly) NSDictionary *indexDescriptions;

-(NSSet *)referencesInIndex:(NSString *)indexName forValue:(id)value;
-(NSSet *)referencesInIndex:(NSString *)indexName forValuesNotEqualToValue:(id)value;

-(NSSet *)referencesInIndex:(NSString *)indexName forValuesInSet:(NSArray *)value;
-(NSSet *)referencesInIndex:(NSString *)indexName forValuesNotInSet:(NSArray *)value;

-(NSSet *)referencesInIndex:(NSString *)indexName lessThanValue:(id)value;
-(NSSet *)referencesInIndex:(NSString *)indexName lessThanOrEqualToValue:(id)value;
-(NSSet *)referencesInIndex:(NSString *)indexName greaterThanValue:(id)value;
-(NSSet *)referencesInIndex:(NSString *)indexName greaterThanOrEqualToValue:(id)value;


@end
