//
//  BCOColumn.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>
@class BCOColumnDescription;
@protocol BCOColumnValue;



@interface BCOColumn : NSObject <NSCopying>

-(instancetype)initWithIndexColumnDescription:(BCOColumnDescription *)indexColumnDescription;

@property(nonatomic, readonly) BCOColumnDescription *indexColumnDescription;

//Entry Updating
-(id<BCOColumnValue>)generateColumnValueForObject:(id)object;

-(void)addRecord:(id)record forColumnValue:(id<BCOColumnValue>)value;
-(void)removeRecord:(id)record forColumnValue:(id<BCOColumnValue>)value;

//Object Access
-(NSSet *)recordsForValue:(id)value;
-(NSSet *)recordsForValuesInSet:(NSSet *)values;
-(NSSet *)recordsWithValueLessThan:(id)value;
-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value;
-(NSSet *)recordsWithValueGreaterThan:(id)value;
-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value;
-(NSSet *)recordsWithValueNotEqualTo:(id)value;

@end
