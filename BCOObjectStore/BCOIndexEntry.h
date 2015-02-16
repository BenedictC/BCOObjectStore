//
//  BCOIndexEntry.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 22/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndexEntry : NSObject <NSCopying, NSMutableCopying>

-(instancetype)initWithIndexValue:(id)value references:(NSSet *)references;
@property(nonatomic, readonly) id indexValue;
@property(nonatomic, readonly) NSSet *references;

@end



@interface BCOMutableIndexEntry : BCOIndexEntry
@property(nonatomic) id indexValue;
-(void)addReference:(id)reference;
-(void)removeReference:(id)reference;
@end
