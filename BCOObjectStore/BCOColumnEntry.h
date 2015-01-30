//
//  BCOColumnEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOColumnEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithValue:(id)value records:(NSSet *)records;
@property(nonatomic, readonly) id value;
@property(nonatomic, readonly) NSSet *records;

@end



@interface BCOMutableColumnEntry : BCOColumnEntry
@property(nonatomic) id value;
-(void)addRecord:(id)record;
-(void)removeRecord:(id)record;
@end
