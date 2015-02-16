//
//  BCOObjectStorageEnumerator.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCOObjectReference;



@protocol BCOObjectStorageEnumerator <NSObject>

-(void)enumerateObjectReferencesUsingBlock:(void(^)(BCOObjectReference *reference, BOOL *stop))block;
-(void)enumerateObjectReferencesAndObjectsUsingBlock:(void(^)(BCOObjectReference *reference, id object, BOOL *stop))block;

@end


