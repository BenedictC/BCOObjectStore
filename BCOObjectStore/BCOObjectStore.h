//
//  BCOObjectStore.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"

@protocol BCOOCallbackToken;



@interface BCOObjectStore : NSObject

#pragma mark instance life cycle
+(instancetype)objectStoreWithBackgroundQueue;
+(instancetype)objectStoreWithMainQueue;
-(instancetype)initWithDispatchQueue:(dispatch_queue_t)queue __attribute__((objc_designated_initializer));

#pragma mark Configuring the stores
-(void)setIndexDescription:(BCOIndexDescription *)indexDescription forName:(NSString *)indexName;

#pragma mark Setting stores content
-(void)setObjects:(NSSet *)objects;

#pragma mark Accessing objects
@property(atomic, readonly) BCOObjectStoreSnapshot *snapshot;
//This is method is simply an alternative to KVO on currentSnapshot.
-(id<BCOOCallbackToken>)registerChangeHandler:(void(^)(BCOObjectStoreSnapshot *oldSnapshot, BCOObjectStoreSnapshot *newSnapshot))changeHandler;

@end




@protocol BCOCallbackToken <NSObject>
-(void)unregister;
@end


