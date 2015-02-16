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

-(void)addReference:(id)reference forIndexValue:(id)value;
-(void)removeReference:(id)reference forIndexValue:(id)value;

@end



@interface BCOIndex : NSObject <BCOIndexBuilder>

-(instancetype)initWithIndexDescription:(BCOIndexDescription *)indexDescription;

@property(nonatomic, readonly) BCOIndexDescription *indexDescription;

//Object Access
-(NSSet *)referencesWithValueLessThan:(id)value;
-(NSSet *)referencesWithValueLessThanOrEqualTo:(id)value;
-(NSSet *)referencesWithValueGreaterThan:(id)value;
-(NSSet *)referencesWithValueGreaterThanOrEqualTo:(id)value;

-(NSSet *)referencesForValue:(id)value;
-(NSSet *)referencesWithValueNotEqualTo:(id)value;

-(NSSet *)referencesForValuesInSet:(NSArray *)values;
-(NSSet *)referencesForValuesNotInSet:(NSArray *)values;

@end
