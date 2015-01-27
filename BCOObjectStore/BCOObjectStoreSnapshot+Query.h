//
//  BCOObjectStoreSnapshot+Query.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot.h"
@class BCOObjectStorageContainer;



@interface BCOObjectStoreSnapshot (Query)

-(NSArray *)executeQuery:(NSString *)queryString subsitutionVariable:(NSDictionary *)subsitutionVariable objectStorage:(BCOObjectStorageContainer *)storage indexes:(NSDictionary *)indexes;

@end
