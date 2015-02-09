//
//  BCOObjectStorageContainer.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;



@protocol BCOObjectStorageContainerBuilder <NSObject, NSCopying>

//Content updating
-(BCOStorageRecord *)addObject:(id)object;
-(void)removeObjectForStorageRecord:(BCOStorageRecord *)storageRecord;

@end



@interface BCOObjectStorageContainer : NSObject <BCOObjectStorageContainerBuilder>

//Instance life cycle
+(BCOObjectStorageContainer *)objectStorageWithPersistentStorePath:(NSString *)path;

//Random content access
-(id)objectForStorageRecord:(BCOStorageRecord *)storageRecord;
-(BCOStorageRecord *)storageRecordForObject:(id)object;

//Enumerated content access
-(NSArray *)allStorageRecords;
-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block;

//Archiving
-(BOOL)writeToPath:(NSString *)path error:(NSError **)ourError;

@end
