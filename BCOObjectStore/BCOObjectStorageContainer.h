//
//  BCOObjectStorageContainer.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOObjectStorageEnumeratorProtocol.h"

@class BCOStorageRecord;



@interface BCOObjectStorageContainer : NSObject <BCOObjectStorageEnumerator>

//Instance life cycle
+(BCOObjectStorageContainer *)objectStorageWithPersistentStorePath:(NSString *)path objectDeserializer:(id(^)(NSData *))deserializer error:(NSError **)outError;
//Archiving
-(BOOL)writeToPath:(NSString *)path error:(NSError **)ourError objectSerializer:(NSData *(^)(id))serializer;

//Random content access
-(id)objectForStorageRecord:(BCOStorageRecord *)storageRecord;
-(BCOStorageRecord *)storageRecordForObject:(id)object;

//Enumerated content access
-(id)storageRecordEnumeratorWithStorageRecords:(id<NSFastEnumeration>)records;

@end
