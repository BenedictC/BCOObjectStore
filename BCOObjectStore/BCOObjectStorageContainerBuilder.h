//
//  BCOObjectStorageContainerBuilder.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCOObjectStorageContainer;
@class BCOStorageRecord;



@interface BCOObjectStorageContainerBuilder : NSObject

+(instancetype)builderWithPreviousStorageContainer:(BCOObjectStorageContainer *)previousContainer;

-(BCOStorageRecord *)addObject:(id)object;
-(void)removeObjectForStorageRecord:(BCOStorageRecord *)storageRecord;

-(BCOObjectStorageContainer *)finalize;

@end
