//
//  BCOColumnEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOColumnEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithValue:(id)value objects:(NSSet *)objects;
@property(nonatomic, readonly) id value;
@property(nonatomic, readonly) NSSet *objects;

@end



@interface BCOMutableColumnEntry : BCOColumnEntry
@property(nonatomic) id value;
@property(nonatomic, readonly) NSMutableSet *objects;
@end
