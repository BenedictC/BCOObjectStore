//
//  BCOObjectStoreCoordinator.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BCOObjectStoreCoordinatorSnapshot;
@protocol BCOOCallbackToken;



@interface BCOObjectStoreCoordinator : NSObject

#pragma mark instance life cycle
+(instancetype)objectStoreCoordinatorWithBackgroundQueue;
+(instancetype)objectStoreCoordinatorWithMainQueue;
-(instancetype)initWithDispatchQueue:(dispatch_queue_t)queue __attribute__((objc_designated_initializer));

#pragma mark Configuring the stores
-(void)addPrimaryIndexForClass:(Class)indexedClass valueKeyPath:(NSString *)valueKeyPath;
//TODO: What about subclasses? If B inherits from A and we have an index for A should we included objects of type B?
//      What if an instance of B has the same uniqueID as an instance of A?
//TODO: Additional indexes can have duplicate values.
//-(void)addIndexWithName:(NSString *)indexName forClass:(Class)indexedClass valueKeyPath:(NSString *)valueKeyPath;
#pragma mark Setting stores content
-(void)setObjects:(NSSet *)objects forStoreWithName:(NSString *)storeName;

#pragma mark Accessing objects
@property(atomic, readonly) id<BCOObjectStoreCoordinatorSnapshot> snapshot;
//This is method is simply an alternative to KVO on currentSnapshot.
-(id<BCOOCallbackToken>)registerChangeHandler:(void(^)(id<BCOObjectStoreCoordinatorSnapshot> oldSnapshot, id<BCOObjectStoreCoordinatorSnapshot> newSnapshot))changeHandler;

@end



@protocol BCOObjectStoreCoordinatorSnapshot <NSObject>

@property(readonly) NSDictionary *storesByName;

-(NSDictionary *)fetchAllObjectsOfClass:(Class)indexedClass;
-(id)fetchObjectWithPrimaryID:(id)primaryID class:(Class)class;

-(NSDictionary *)fetchAllObjectsOfClass:(Class)indexedClass fromStores:(NSArray *)storeNames;
-(id)fetchObjectWithPrimaryID:(Class)indexedClass class:(id)uniqueID fromStores:(NSArray *)storeNames;

@end



@protocol BCOCallbackToken <NSObject>
-(void)unregister;
@end


