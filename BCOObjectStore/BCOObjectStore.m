//
//  BCOObjectStore.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStore.h"

#import "BCOObjectStoreSnapshot.h"
#import "BCOIndexDescription.h"



#pragma mark - BCOObjectStore
@interface BCOObjectStore ()

@property(nonatomic, readonly) BCOObjectStoreConfiguration *configuration;

@end



@implementation BCOObjectStore

#pragma mark - instance life cycle
-(instancetype)init
{
    return [self initWithConfiguration:nil];
}


-(instancetype)initWithConfiguration:(BCOObjectStoreConfiguration *)configuration
{
    NSParameterAssert(configuration);

    self = [super init];
    if (self == nil) return nil;

    _configuration = [configuration copy];
    _snapshot = [BCOObjectStoreSnapshot new];

    return self;
}



#pragma mark - 'properties'
-(void)setSnapshot:(BCOObjectStoreSnapshot *(^)(BCOObjectStoreSnapshot *oldSnapshot))block
{
    typedef NS_ENUM(NSUInteger, SyncMode){
        SyncModeQueue,
        SyncModeCurrentThread,
    };

    dispatch_queue_t queue = self.configuration.dispatchQueue;
    SyncMode mode = (queue == NULL) ? SyncModeCurrentThread : SyncModeQueue;

    switch (mode) {
        case SyncModeQueue:
        {
            //We have to use dispatch_barrier_async instead of dispatch_async because the dispatch queue may be
            //concurrent which could lead to problems.
            dispatch_barrier_async(queue, ^{
                _snapshot = block(self.snapshot);
            });
            break;
        }
        case SyncModeCurrentThread:
        {
            @synchronized(self) {
                _snapshot = block(self.snapshot);
            }
            break;
        }
    }
}



#pragma mark - Setting stores content
-(void)setObjectsUsingBlock:(void(^)(BCOObjectStoreSnapshot *currentSnapshot, BCOObjectStoreSetObjectsCompletionHandler completionHandler))setObjectsBlock
{
    [self setSnapshot:^(BCOObjectStoreSnapshot *oldSnapshot) {
        __block BCOObjectStoreSnapshot *newSnapshot = nil;
        setObjectsBlock(oldSnapshot, ^(NSSet *objects){
            newSnapshot = [oldSnapshot snapshotWithObjects:objects];
        });
        return newSnapshot;
    }];
}



-(void)updateObjectsUsingBlock:(void(^)(BCOObjectStoreSnapshot *currentSnapshot, BCOObjectStoreUpdateObjectsCompletionHandler updateCompletionHandler))updateBlock
{
    [self setSnapshot:^(BCOObjectStoreSnapshot *oldSnapshot) {
        __block BCOObjectStoreSnapshot *newSnapshot = nil;
        updateBlock(oldSnapshot, ^(NSSet *insertedObjects, NSSet *deletedObjects){
            newSnapshot = [oldSnapshot snapshotByInsertingObjects:insertedObjects deletingObjects:deletedObjects];
        });
        return newSnapshot;
    }];
}

@end
