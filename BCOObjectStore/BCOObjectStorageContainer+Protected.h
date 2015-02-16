//
//  BCOObjectStorageContainer+Protected.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStorageContainer.h"



@interface BCOObjectStorageContainer ()//Protected

-(instancetype)initWithObjectsByStorageRecords:(NSDictionary *)objectsByStorageRecords previousContainer:(BCOObjectStorageContainer *)previousContainer  __attribute__((objc_designated_initializer));

@property(nonatomic, readonly) NSDictionary *objectsByStorageRecords;
@property(nonatomic, readonly) BCOObjectStorageContainer *previousContainer;

@end
