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



@interface BCOObjectStore : NSObject

// Factories
+(instancetype)objectStoreWithBackgroundQueue;
+(instancetype)objectStoreWithMainQueue;

// instance life cycle
-(instancetype)initWithDispatchQueue:(dispatch_queue_t)queue __attribute__((objc_designated_initializer));

// Configuring the stores
-(void)addIndexDescription:(BCOIndexDescription *)indexDescription withName:(NSString *)indexName;

// Setting stores content
//TODO: Can we structure this better for performing updates?
-(void)setObjects:(NSSet *)objects;

// Accessing objects
@property(atomic, readonly) BCOObjectStoreSnapshot *snapshot;

@end