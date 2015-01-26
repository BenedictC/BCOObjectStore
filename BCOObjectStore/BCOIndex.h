//
//  BCOIndex.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>



@interface BCOIndex : NSObject <NSCopying>

-(instancetype)initWithComparator:(NSComparator)comparator;

@property(nonatomic, readonly) NSComparator comparator;

//Entry updating
-(void)addObject:(id)object forKey:(id)key;
-(void)removeObject:(id)object forKey:(id)key;



//Object Access
-(NSSet *)objectsForKey:(id)key;
-(NSSet *)objectsForKeysInSet:(NSSet *)keys;
-(NSSet *)objectsLessThanKey:(id)key;
-(NSSet *)objectsLessThanOrEqualToKey:(id)key;
-(NSSet *)objectsGreaterThanKey:(id)key;
-(NSSet *)objectsGreaterThanOrEqualToKey:(id)key;
-(NSSet *)objectsForKeysNotEqualToKey:(id)key;

@end
