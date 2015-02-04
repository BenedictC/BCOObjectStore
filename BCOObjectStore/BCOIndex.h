//
//  BCOIndex.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOIndexDescription;



@interface BCOIndex : NSObject <NSCopying>

-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription;

@property(nonatomic, readonly) BCOIndexDescription *indexDescription;

//Entry Updating
-(id)generateIndexValueForObject:(id)object;

-(void)addRecord:(id)record forIndexValue:(id)value;
-(void)removeRecord:(id)record forIndexValue:(id)value;

//Object Access
-(NSSet *)recordsWithValueLessThan:(id)value;
-(NSSet *)recordsWithValueLessThanOrEqualTo:(id)value;
-(NSSet *)recordsWithValueGreaterThan:(id)value;
-(NSSet *)recordsWithValueGreaterThanOrEqualTo:(id)value;

-(NSSet *)recordsForValue:(id)value;
-(NSSet *)recordsWithValueNotEqualTo:(id)value;

-(NSSet *)recordsForValuesInSet:(NSArray *)values;
-(NSSet *)recordsForValuesNotInSet:(NSArray *)values;

@end
