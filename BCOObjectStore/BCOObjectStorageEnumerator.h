//
//  BCOObjectStorageEnumerator.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStorageEnumeratorProtocol.h"

@class BCOObjectStorageContainer;



@interface BCOObjectStorageEnumerator : NSObject <BCOObjectStorageEnumerator>

-(instancetype)initWithStorageContainer:(BCOObjectStorageContainer *)storageContainer references:(id<NSFastEnumeration>)references;
@property(nonatomic, readonly) BCOObjectStorageContainer *storageContainer;
@property(nonatomic, readonly) id<NSFastEnumeration> references;

@end

