//
//  BCOIndekz.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 29/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOIndekzEntry;



@interface BCOIndekz : NSObject <NSCopying>

-(instancetype)initWithColumnDescriptions:(NSDictionary *)columnDescriptions;

@property(nonatomic, readonly) NSDictionary *columnDescriptions;

-(BCOIndekzEntry *)insertEntryForRecord:(id)record byIndexingObject:(id)object;
-(void)removeEntry:(BCOIndekzEntry *)indekzEntry;

-(NSSet *)recordsInColumn:(NSString *)columnName forValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName forValuesNotEqualToValue:(id)value;

-(NSSet *)recordsInColumn:(NSString *)columnName forValuesInSet:(NSSet *)value;
-(NSSet *)recordsInColumn:(NSString *)columnName forValuesNotInSet:(NSSet *)value;

-(NSSet *)recordsInColumn:(NSString *)columnName lessThanValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName lessThanOrEqualToValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanOrEqualToValue:(id)value;


@end
