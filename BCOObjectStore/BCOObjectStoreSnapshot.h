//
//  BCOObjectStoreSnapshot.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCOObjectStoreSnapshotProtocol.h"



@interface BCOObjectStoreSnapshot : NSObject <BCOObjectStoreSnapshot>

//Snapshot creation
+(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions;

-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects;
-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects;
+(BCOObjectStoreSnapshot *)snapshotFromSnapshotArchive:(NSData *)representation indexDescriptions:(NSDictionary *)indexDescriptions;

//Properties
-(NSDictionary *)indexDescriptions;

@end
