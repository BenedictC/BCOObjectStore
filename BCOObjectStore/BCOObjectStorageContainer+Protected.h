//
//  BCOObjectStorageContainer+Protected.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStorageContainer.h"

@class BCOObjectStorageContainerPersistentStorageManager;



@interface BCOObjectStorageContainer ()//Protected

-(instancetype)initWithObjectsByObjectReferences:(NSDictionary *)objectsByObjectReferences previousContainer:(BCOObjectStorageContainer *)previousContainer persistentStorageManager:(BCOObjectStorageContainerPersistentStorageManager *)persistentStorageManager  __attribute__((objc_designated_initializer));
@property(nonatomic, readonly) NSDictionary *objectsByObjectReferences;
@property(nonatomic, readonly) BCOObjectStorageContainer *previousContainer;
@property(nonatomic, readonly) BCOObjectStorageContainerPersistentStorageManager *persistentStorageManager;

@end
