//
//  BCOObjectStorageContainerBuilder.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCOObjectStorageContainer;
@class BCOObjectReference;



@interface BCOObjectStorageContainerBuilder : NSObject

+(instancetype)builderWithPreviousStorageContainer:(BCOObjectStorageContainer *)previousContainer;

-(BCOObjectReference *)addObject:(id)object;
-(void)removeObjectForObjectReference:(BCOObjectReference *)objectReference;

-(BCOObjectStorageContainer *)finalize;

@end
