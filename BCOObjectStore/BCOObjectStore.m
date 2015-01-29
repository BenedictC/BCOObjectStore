//
//  BCOObjectStore.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStore.h"

#import "BCOObjectStoreSnapshot.h"
#import "BCOColumnDescription.h"



#pragma mark - BCOObjectStore
@interface BCOObjectStore ()
{
    BCOObjectStoreConfiguration *_configuration;
}

@property(atomic, readonly) BCOObjectStoreSnapshot *snapshot;

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
    _snapshot = [BCOObjectStoreSnapshot snapshotFromSnapshotArchive:configuration.initialSnapshotArchive columnDescriptions:configuration.columnDescriptions];

    return self;
}



#pragma mark - 'properties'
-(BCOObjectStoreConfiguration *)configuration
{
    return [_configuration copy];
}



-(id<BCOObjectStoreSnapshot>)currentSnapshot
{
    //setSnapshot: calls will/didChangeValueForKey:
    return self.snapshot;
}



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
                [self willChangeValueForKey:@"currentSnapshot"];
                _snapshot = block(self.snapshot);
                [self didChangeValueForKey:@"currentSnapshot"];
            });
            break;
        }
        case SyncModeCurrentThread:
        {
            @synchronized(self) {
                [self willChangeValueForKey:@"currentSnapshot"];
                _snapshot = block(self.snapshot);
                [self didChangeValueForKey:@"currentSnapshot"];
            }
            break;
        }
    }
}



#pragma mark - Setting stores content
-(void)setObjectsUsingBlock:(void(^)(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreSetObjectsCompletionHandler completionHandler))setObjectsBlock
{
    [self setSnapshot:^(BCOObjectStoreSnapshot *oldSnapshot) {
        __block BCOObjectStoreSnapshot *newSnapshot = nil;
        setObjectsBlock(oldSnapshot, ^(NSSet *objects){
            newSnapshot = [oldSnapshot snapshotWithObjects:objects];
        });
        return newSnapshot;
    }];
}



-(void)updateObjectsUsingBlock:(void(^)(id<BCOObjectStoreSnapshot> currentSnapshot, BCOObjectStoreUpdateObjectsCompletionHandler updateCompletionHandler))updateBlock
{
    [self setSnapshot:^(BCOObjectStoreSnapshot *oldSnapshot) {
        __block BCOObjectStoreSnapshot *newSnapshot = nil;
        updateBlock(oldSnapshot, ^(NSSet *insertedObjects, NSSet *deletedObjects){
            newSnapshot = [oldSnapshot snapshotByInsertingObjects:insertedObjects deletingObjects:deletedObjects];
        });
        return newSnapshot;
    }];
}



#pragma mark - BCOObjectStoreSnapshotProtocol
-(NSArray *)executeQuery:(NSString *)query
{
    return [self.snapshot executeQuery:query];
}



-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable;
{
    return [self.snapshot executeQuery:query subsitutionVariable:subsitutionVariable];
}



-(NSData *)snapshotArchive
{
    return self.snapshot.snapshotArchive;
}

@end
