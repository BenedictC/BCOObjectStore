//
//  BCOObjectStorageContainer.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>
@class BCOStorageRecord;



@interface BCOObjectStorageContainer : NSObject <NSCopying>

//Instance life cycle
+(BCOObjectStorageContainer *)objectStorageWithObjects:(NSSet *)objects;

+(BCOObjectStorageContainer *)objectStorageWithData:(NSData *)data;

-(NSData *)dataRepresentation;

//Content updating
-(BCOStorageRecord *)addObject:(id)object;
-(void)removeObjectForStorageRecord:(BCOStorageRecord *)storageRecord;

//Random content access
-(id)objectForStorageRecord:(BCOStorageRecord *)storageRecord;
-(BCOStorageRecord *)storageRecordForObject:(id)object;

//Enumerated content access
-(NSArray *)allStorageRecords;
-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block;

@end
