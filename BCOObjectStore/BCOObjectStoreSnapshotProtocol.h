//
//  BCOObjectStoreSnapshotProtocol.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>



@protocol BCOObjectStoreSnapshot <NSObject>

//Archiving
-(BOOL)writeToPath:(NSString *)path error:(NSError **)ourError;

//Querying
-(id)executeQuery:(NSString *)query;
-(id)executeQuery:(NSString *)query substitutionVariables:(NSDictionary *)substitutionVariables;

@end
