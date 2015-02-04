//
//  BCOIndexEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndexEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithIndexValue:(id)value records:(NSSet *)records;
@property(nonatomic, readonly) id indexValue;
@property(nonatomic, readonly) NSSet *records;

@end



@interface BCOMutableIndexEntry : BCOIndexEntry
@property(nonatomic) id indexValue;
-(void)addRecord:(id)record;
-(void)removeRecord:(id)record;
@end
