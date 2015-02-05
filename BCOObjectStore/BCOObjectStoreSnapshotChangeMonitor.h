//
//  BCOObjectStoreSnapshotChangeMonitor.h
//  Pods
//
//  Created by Benedict Cohen on 05/02/2015.
//
//

#import <Foundation/Foundation.h>

@class BCOObjectStore;
@class BCOQuery;
@protocol BCOObjectStoreSnapshot;



@interface BCOObjectStoreSnapshotChangeMonitor : NSObject

-(instancetype)initWithObjectStore:(BCOObjectStore *)objectStore query:(BCOQuery *)query queue:(dispatch_queue_t)queue changeHandler:(void(^)(id result, id<BCOObjectStoreSnapshot> snapshot))changeHandler;

@property(nonatomic, readonly) BCOObjectStore *objectStore;
@property(nonatomic, readonly) BCOQuery *query;
@property(nonatomic, readonly) dispatch_queue_t queue;
@property(nonatomic, readonly) void(^changeHandler)(id result, id<BCOObjectStoreSnapshot>snapshot);

-(void)start;
-(void)stop;

@end
