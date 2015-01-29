//
//  BCOColumn.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import <Foundation/Foundation.h>
@class BCOIndexColumnDescription;
@protocol BCOColumnKey;



@interface BCOColumn : NSObject <NSCopying>

-(instancetype)initWithIndexColumnDescription:(BCOIndexColumnDescription *)indexColumnDescription;

@property(nonatomic, readonly) BCOIndexColumnDescription *indexColumnDescription;

//Entry Updating
-(id<BCOColumnKey>)generateColumnKeyForObject:(id)object;

-(void)addRecord:(id)record forKey:(id<BCOColumnKey>)key;
-(void)removeRecord:(id)record forKey:(id<BCOColumnKey>)key;

//Object Access
-(NSSet *)recordsForKey:(id)key;
-(NSSet *)recordsForKeysInSet:(NSSet *)keys;
-(NSSet *)recordsLessThanKey:(id)key;
-(NSSet *)recordsLessThanOrEqualToKey:(id)key;
-(NSSet *)recordsGreaterThanKey:(id)key;
-(NSSet *)recordsGreaterThanOrEqualToKey:(id)key;
-(NSSet *)recordsForKeysNotEqualToKey:(id)key;

@end
