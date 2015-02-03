//
//  BCOObjectStoreSnapshot+Query.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot.h"

@class BCOObjectStorageContainer;
@class BCOIndekz;



@interface BCOObjectStoreSnapshot (Query)

-(NSArray *)executeQuery:(NSString *)queryString subsitutionVariable:(NSDictionary *)subsitutionVariable objectStorage:(BCOObjectStorageContainer *)storage indekz:(BCOIndekz *)indekz;

@end
