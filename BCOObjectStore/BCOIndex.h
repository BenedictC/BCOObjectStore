//
//  BCOIndex.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 29/01/2015.
//
//

#import <Foundation/Foundation.h>
#import "BCOIndexEntry.h"



@interface BCOIndex : NSObject <NSCopying>

-(instancetype)initWithIndexColumnDescriptions:(NSDictionary *)indexColumnDescriptions;

@property(nonatomic, readonly) NSDictionary *indexColumnDescriptions;

-(BCOIndexEntry *)insertEntryForRecord:(id)record byIndexingObject:(id)object;
-(void)removeEntry:(BCOIndexEntry *)indexEntry;

-(NSSet *)recordsInColumn:(NSString *)columnName forKey:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName forKeysInSet:(NSSet *)value;
-(NSSet *)recordsInColumn:(NSString *)columnName lessThanKey:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName lessThanOrEqualToKey:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanKey:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanOrEqualToKey:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName forKeysNotEqualToKey:(id)value;

@end
