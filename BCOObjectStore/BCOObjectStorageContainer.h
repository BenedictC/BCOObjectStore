//
//  BCOObjectStorageContainer.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 26/01/2015.
//
//

#import "BCOObjectStorageEnumeratorProtocol.h"

@class BCOObjectReference;



@interface BCOObjectStorageContainer : NSObject <BCOObjectStorageEnumerator>

//Instance factory
+(BCOObjectStorageContainer *)objectStorageWithPersistentStorePath:(NSString *)path objectDeserializer:(id(^)(NSData *))deserializer error:(NSError **)outError;

//Random content access
-(id)objectForObjectReference:(BCOObjectReference *)objectReference;
-(BCOObjectReference *)objectReferenceForObject:(id)object;

//Enumerated content access
-(id)objectReferenceEnumeratorWithObjectReferences:(id<NSFastEnumeration>)references;

//Archiving
-(BOOL)writeToPath:(NSString *)path objectSerializer:(NSData *(^)(id))objectSerializer error:(NSError **)ourError;

@end
