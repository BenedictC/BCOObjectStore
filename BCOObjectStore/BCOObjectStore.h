//
//  BCOObjectStore.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOObjectStoreConfiguration.h"
#import "BCOObjectStoreSnapshotProtocol.h"
#import "BCOQueryResultGroupProtocol.h"



//Object setters
typedef void (^BCOObjectStoreSetObjectsCompletionHandler)(NSSet *objects);
typedef void (^BCOObjectStoreUpdateObjectsCompletionHandler)(NSSet *insertedObjects, NSSet *deletedObjects);



@interface BCOObjectStore : NSObject <BCOObjectStoreSnapshot>

//Instance life cycle
-(instancetype)initWithConfiguration:(BCOObjectStoreConfiguration *)configuration __attribute__((objc_designated_initializer));
-(BCOObjectStoreConfiguration *)configuration;

//Setting the stores' content
-(void)setObjectsUsingBlock:(void(^)(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreSetObjectsCompletionHandler completionHandler))setObjectsBlock;
-(void)updateObjectsUsingBlock:(void(^)(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreUpdateObjectsCompletionHandler completionHandler))updateBlock;

//Snapshot access (to allow queries to be run on the same data set without concurrency issues)
@property(nonatomic, readonly) id<BCOObjectStoreSnapshot> currentSnapshot;

//Change monitoring
-(id)monitorStoreForChangesToQuery:(NSString *)queryString substitutionVariables:(NSDictionary *)substitutionVariables changeHandler:(void(^)(id result, id<BCOObjectStoreSnapshot> snapshot))changeHandler;

@end
