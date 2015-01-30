//
//  BCOColumn.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOColumnDescription;



@interface BCOColumn : NSObject <NSCopying>

-(instancetype)initWithColumnDescription:(BCOColumnDescription *)columnDescription;

@property(nonatomic, readonly) BCOColumnDescription *columnDescription;

//Entry Updating
-(id)generateColumnValueForObject:(id)object;

-(void)addRecord:(id)record forColumnValue:(id)value;
-(void)removeRecord:(id)record forColumnValue:(id)value;

//Object Access
-(NSSet *)recordsForValue:(id)value;
-(NSSet *)recordsForValuesInSet:(NSSet *)values;
-(NSSet *)recordsWithValueLessThan:(id)value;
-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value;
-(NSSet *)recordsWithValueGreaterThan:(id)value;
-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value;
-(NSSet *)recordsWithValueNotEqualTo:(id)value;

@end
