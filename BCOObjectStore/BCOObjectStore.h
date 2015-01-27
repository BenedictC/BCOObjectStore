//
//  BCOObjectStore.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOObjectStoreConfiguration.h"
#import "BCOObjectStoreSnapshot.h"



//Object setters
typedef void (^BCOObjectStoreSetObjectsCompletionHandler)(NSSet *objects);
typedef void (^BCOObjectStoreUpdateObjectsCompletionHandler)(NSSet *insertedObjects, NSSet *deletedObjects);



@interface BCOObjectStore : NSObject

// Instance life cycle
-(instancetype)initWithConfiguration:(BCOObjectStoreConfiguration *)configuration __attribute__((objc_designated_initializer));
-(BCOObjectStoreConfiguration *)configuration;

// Setting stores content
-(void)setObjectsUsingBlock:(void(^)(BCOObjectStoreSnapshot *currentSnapshot, BCOObjectStoreSetObjectsCompletionHandler completionHandler))setObjectsBlock;
-(void)updateObjectsUsingBlock:(void(^)(BCOObjectStoreSnapshot *currentSnapshot, BCOObjectStoreUpdateObjectsCompletionHandler completionHandler))updateBlock;

// Accessing objects
@property(atomic, readonly) BCOObjectStoreSnapshot *snapshot;

@end



@interface BCOObjectStore (Debugging)
-(void)setSnapshot:(BCOObjectStoreSnapshot *(^)(BCOObjectStoreSnapshot *oldSnapshot))block;
@end
