//
//  BCOIndex.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOIndexDescription;

@class BCOIndex;



@protocol BCOIndexBuilder <NSObject, NSCopying>

//Entry Updating
-(id)generateIndexValueForObject:(id)object;

-(void)addRecord:(id)record forIndexValue:(id)value;
-(void)removeRecord:(id)record forIndexValue:(id)value;

@end



@interface BCOIndex : NSObject <BCOIndexBuilder>

-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription;

@property(nonatomic, readonly) BCOIndexDescription *indexDescription;

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
