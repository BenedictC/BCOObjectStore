//
//  BCOIndex.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndex : NSObject <NSCopying>

-(NSSet *)objectsForKey:(id)key;

-(void)addObject:(id)object forKey:(id)key;

-(void)removeObject:(id)object forKey:(id)key;

//-(NSArray *)objectsInRange...
//-(NSArray *)objectsForKeys:(NSSet *)keys;

@end
