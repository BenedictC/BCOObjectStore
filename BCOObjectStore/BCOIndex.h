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

-(instancetype)initWithColumnDescriptions:(NSDictionary *)columnDescriptions;

@property(nonatomic, readonly) NSDictionary *columnDescriptions;

-(BCOIndexEntry *)insertEntryForRecord:(id)record byIndexingObject:(id)object;
-(void)removeEntry:(BCOIndexEntry *)indexEntry;

-(NSSet *)recordsInColumn:(NSString *)columnName forValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName forValuesInSet:(NSSet *)value;
-(NSSet *)recordsInColumn:(NSString *)columnName lessThanValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName lessThanOrEqualToValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName greaterThanOrEqualToValue:(id)value;
-(NSSet *)recordsInColumn:(NSString *)columnName forKeysNotEqualToValue:(id)value;

@end
