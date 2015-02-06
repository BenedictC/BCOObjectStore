//
//  BCOObjectStoreSnapshotChangeMonitor.m
//  Pods
//
//  Created by Benedict Cohen on 05/02/2015.
//
//

#import "BCOObjectStoreSnapshotChangeMonitor.h"
#import "BCOObjectStore+Protected.h"
#import "BCOObjectStoreSnapshot.h"



@interface BCOObjectStoreSnapshotChangeMonitor ()

@property(nonatomic, getter=isMonitoring) BOOL monitoring;
@property(nonatomic) id previousResult;

@end



@implementation BCOObjectStoreSnapshotChangeMonitor

#pragma mark - instance life cycle
-(instancetype)initWithObjectStore:(BCOObjectStore *)objectStore query:(BCOQuery *)query queue:(dispatch_queue_t)queue changeHandler:(void(^)(id result, id<BCOObjectStoreSnapshot> snapshot))changeHandler;
{
    self = [super init];
    if (self == nil) return nil;

    _objectStore = objectStore;
    _query = query;
#if !OS_OBJECT_USE_OBJC
    if (queue) dispatch_retain(queue);
#endif
    _queue = queue;
    _changeHandler = changeHandler;

    return self;
}



-(void)dealloc
{
    [self stop];

#if !OS_OBJECT_USE_OBJC
    if (_queue) dispatch_release(_queue);
#endif

}



#pragma mark - threading
-(void)executeReadBlock:(void(^)(void))block
{
    if (self.queue != NULL) {
        dispatch_async(self.queue, block);

    } else @synchronized(self) {
        block();
    }
}



-(void)executeWriteBlock:(void(^)(void))block
{
    if (self.queue != NULL) {
        dispatch_barrier_async(self.queue, block);

    } else @synchronized(self) {
        block();
    }
}



#pragma mark - monitoring
-(void)start
{
    [self executeReadBlock:^{
        if (self.monitoring) return;

        [self executeWriteBlock:^{
            //Re-read
            if (self.monitoring) return;

            //Write
            self.previousResult = nil; //Reset the results
            self.monitoring = YES;
            [self.objectStore addObserver:self forKeyPath:NSStringFromSelector(@selector(snapshot)) options:NSKeyValueObservingOptionNew context:(void *)self];

            //Fire the initial query
            [self invokeChangeHandlerWithSnapshot:self.objectStore.snapshot];
        }];
    }];
}



-(void)stop
{
    [self executeReadBlock:^{
        if (!self.monitoring) return;

        [self executeWriteBlock:^{
            //Re-read
            if (!self.monitoring) return;

            //Write
            self.monitoring = NO;
            [self.objectStore removeObserver:self forKeyPath:NSStringFromSelector(@selector(snapshot)) context:(void *)self];
        }];
    }];
}



#pragma mark - callback
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //We don't bother checking keyPath/object/context because we're only observing one property.
    BCOObjectStoreSnapshot *snapshot = change[NSKeyValueChangeNewKey];
    [self invokeChangeHandlerWithSnapshot:snapshot];
}



-(void)invokeChangeHandlerWithSnapshot:(BCOObjectStoreSnapshot *)snapshot
{
    [self executeReadBlock:^{
        //Execute the query against the new snapshot
        id freshResult = [snapshot executeQueryObject:self.query];

        //Compare results
        id previousResult = self.previousResult;
        BOOL didResultChange = ![previousResult isEqual:freshResult];
        //Done?
        if (!didResultChange) return;

        //Store result and fire the change handler
        [self executeWriteBlock:^{
            self.previousResult = freshResult;
            dispatch_async(dispatch_get_main_queue(), ^{
                self.changeHandler(freshResult, snapshot);
            });
        }];
    }];
}

@end
