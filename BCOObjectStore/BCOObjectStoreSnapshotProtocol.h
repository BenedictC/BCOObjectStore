//
//  BCOObjectStoreSnapshotProtocol.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>



@protocol BCOObjectStoreSnapshot <NSObject>

//Querying
-(id)executeQuery:(NSString *)query;
-(id)executeQuery:(NSString *)query substitutionVariables:(NSDictionary *)substitutionVariables;

@end
