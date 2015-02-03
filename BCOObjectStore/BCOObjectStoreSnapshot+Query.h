//
//  BCOObjectStoreSnapshot+Query.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot.h"

@class BCOObjectStorageContainer;
@class BCOQueryCatalog;



@interface BCOObjectStoreSnapshot (Query)
/**
 queryString: 
 SELECT: * for whole objects or exactly one field name. All objects in the result must respond to the field name with a non-nil value.
 WHERE:
 GROUP BY:
 ORDER BY:

 @param queryString         <#queryString description#>
 @param subsitutionVariable <#subsitutionVariable description#>
 @param storage             <#storage description#>
 @param queryCatalog

 @return <#return value description#>
 */
-(NSArray *)executeQuery:(NSString *)queryString subsitutionVariable:(NSDictionary *)subsitutionVariable objectStorage:(BCOObjectStorageContainer *)storage queryCatalog:(BCOQueryCatalog *)queryCatalog;

@end
