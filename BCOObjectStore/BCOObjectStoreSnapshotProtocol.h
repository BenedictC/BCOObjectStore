//
//  BCOObjectStoreSnapshotProtocol.h
//  Pods
//
//  Created by Benedict Cohen on 27/01/2015.
//
//

#import <Foundation/Foundation.h>



@protocol BCOObjectStoreSnapshot <NSObject>

//Archiving
-(NSData *)snapshotArchive;

//Querying
-(NSArray *)executeQuery:(NSString *)query;
-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable;

@end
