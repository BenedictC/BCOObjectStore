//
//  BCOObjectStoreSnapshot+Query.h
//  Pods
//
//  Created by Benedict Cohen on 23/01/2015.
//
//

#import "BCOObjectStoreSnapshot.h"



@interface BCOObjectStoreSnapshot (Query)

-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable objects:(NSSet *)objects indexes:(NSDictionary *)indexes;

@end
