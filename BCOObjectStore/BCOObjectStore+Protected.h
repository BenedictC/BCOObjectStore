//
//  BCOObjectStore+Protected.h
//  Pods
//
//  Created by Benedict Cohen on 05/02/2015.
//
//

#import "BCOObjectStore.h"
@class BCOObjectStoreSnapshot;



@interface BCOObjectStore (Protected)
@property(nonatomic, readonly) BCOObjectStoreSnapshot *snapshot;
@end
