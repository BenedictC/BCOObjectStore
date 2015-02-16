//
//  BCOObjectStorageEnumerator.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 16/02/2015.
//  Copyright (c) 2015 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BCOStorageRecord;



@protocol BCOObjectStorageEnumerator <NSObject>

-(void)enumerateStorageRecordsUsingBlock:(void(^)(BCOStorageRecord *record, BOOL *stop))block;
-(void)enumerateStorageRecordsAndObjectsUsingBlock:(void(^)(BCOStorageRecord *record, id object, BOOL *stop))block;

@end


