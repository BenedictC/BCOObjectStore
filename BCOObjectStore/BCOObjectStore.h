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



//Object setters
typedef void (^BCOObjectStoreSetObjectsCompletionHandler)(NSSet *objects);
typedef void (^BCOObjectStoreUpdateObjectsCompletionHandler)(NSSet *insertedObjects, NSSet *deletedObjects);



@interface BCOObjectStore : NSObject

//Instance life cycle
-(instancetype)initWithConfiguration:(BCOObjectStoreConfiguration *)configuration __attribute__((objc_designated_initializer));
-(BCOObjectStoreConfiguration *)configuration;

//Setting the stores' content
-(void)setObjectsUsingBlock:(void(^)(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreSetObjectsCompletionHandler completionHandler))setObjectsBlock;
-(void)updateObjectsUsingBlock:(void(^)(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreUpdateObjectsCompletionHandler completionHandler))updateBlock;

//Snapshot access (to allow queries to be run on the same data set without concurrency issues)
@property(nonatomic, readonly) id<BCOObjectStoreSnapshot> currentSnapshot;

@end



@interface BCOObjectStore (BCOObjectStoreSnapshot)

// Accessing objects
-(NSArray *)executeQuery:(NSString *)query;
-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable;

//Archiving
-(NSData *)snapshotArchive;

@end
