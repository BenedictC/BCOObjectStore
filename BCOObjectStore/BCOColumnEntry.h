//
//  BCOColumnEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>
#import "BCOColumnKey.h"



@interface BCOColumnEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithKey:(id<BCOColumnKey>)key objects:(NSSet *)objects;
@property(nonatomic, readonly) id<BCOColumnKey> key;
@property(nonatomic, readonly) NSSet *objects;

-(NSComparisonResult)compare:(BCOColumnEntry *)otherEntry;

@end



@interface BCOMutableIndexEntry : BCOColumnEntry
@property(nonatomic) id<BCOColumnKey> key;
@property(nonatomic, readonly) NSMutableSet *objects;
@end
