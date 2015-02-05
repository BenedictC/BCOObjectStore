//
//  BCOObjectStoreSnapshot.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCOObjectStoreSnapshotProtocol.h"

@class BCOQuery;



@interface BCOObjectStoreSnapshot : NSObject <BCOObjectStoreSnapshot>

//Snapshot creation
+(BCOObjectStoreSnapshot *)snapshotWithPersistentStorePath:(NSString *)path indexDescriptions:(NSDictionary *)indexDescriptions;

-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects;
-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects;

//Properties
-(NSDictionary *)indexDescriptions;

//Object access
-(id)executeQueryObject:(BCOQuery *)query;

@end
