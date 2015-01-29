//
//  BCOColumnEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>
#import "BCOColumnValue.h"



@interface BCOColumnEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithValue:(id<BCOColumnValue>)value objects:(NSSet *)objects;
@property(nonatomic, readonly) id<BCOColumnValue> value;
@property(nonatomic, readonly) NSSet *objects;

-(NSComparisonResult)compare:(BCOColumnEntry *)otherEntry;

@end



@interface BCOMutableIndexEntry : BCOColumnEntry
@property(nonatomic) id<BCOColumnValue> value;
@property(nonatomic, readonly) NSMutableSet *objects;
@end
