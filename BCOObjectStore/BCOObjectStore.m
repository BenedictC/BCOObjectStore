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

@property(atomic, readonly) dispatch_queue_t mutationQueue;

@end



@implementation BCOObjectStore

#pragma mark - instance life cycle
+(instancetype)objectStoreWithBackgroundQueue
{
    id instance = [self alloc];
    NSString *label = [NSString stringWithFormat:@"%p - %@: mutation queue", instance, NSStringFromClass(self)];
    dispatch_queue_t queue = dispatch_queue_create(label.UTF8String, 0);

    return [[self alloc] initWithDispatchQueue:queue];
}



+(instancetype)objectStoreWithMainQueue
{
    dispatch_queue_t queue = dispatch_get_main_queue();

    return [[self alloc] initWithDispatchQueue:queue];
}



-(instancetype)init
{
    return [self initWithDispatchQueue:NULL];
}



-(instancetype)initWithDispatchQueue:(dispatch_queue_t)queue
{
    self = [super init];
    if (self == nil) return nil;

    _mutationQueue = queue;
    _snapshot = [[BCOObjectStoreSnapshot alloc] initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];

    return self;
}



#pragma mark - 'properties'
-(void)setSnapshot:(BCOObjectStoreSnapshot *(^)(BCOObjectStoreSnapshot *oldSnapshot))block
{
    typedef NS_ENUM(NSUInteger, SyncMode){
        SyncModeQueue,
        SyncModeCurrentThread,
    };

    SyncMode mode = (self.mutationQueue == NULL) ? SyncModeCurrentThread : SyncModeQueue;

    switch (mode) {
        case SyncModeQueue:
        {
            dispatch_async(self.mutationQueue, ^{
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



#pragma mark - Configuring the store
-(void)addIndexDescription:(BCOIndexDescription *)indexDescription withName:(NSString *)indexName
{
    NSRange validCharacterRange = ({
        NSCharacterSet *invalidCharacters = [[NSCharacterSet characterSetWithCharactersInString:@"1234567890_qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM"] invertedSet];
        [indexName rangeOfCharacterFromSet:invalidCharacters];
    });

    BOOL isValidIndexName = (validCharacterRange.location == NSNotFound);
    if (!isValidIndexName) {
        [NSException raise:NSInvalidArgumentException format:@"Invalid indexName. indexName must be at least 1 letter long and can only include letters (case-insensitive), numbers and underscore."];
        return;
    }

    [self setSnapshot:^(BCOObjectStoreSnapshot *oldSnapshot) {
        NSMutableDictionary *indexDescriptions = [NSMutableDictionary dictionaryWithObject:indexDescription forKey:indexName];
        [indexDescriptions addEntriesFromDictionary:oldSnapshot.indexDescriptions];
        //TODO: Should we create a method for creating a new snapshot by adding an index?
        return  [[BCOObjectStoreSnapshot alloc] initWithObjects:oldSnapshot.objects indexDescriptions:indexDescriptions];
    }];
}



#pragma mark - Setting stores content
-(void)setObjectsUsingBlock:(NSSet *(^)(BCOObjectStoreSnapshot *currentSnapshot))setObjectsBlock
{
    [self setSnapshot:^(BCOObjectStoreSnapshot *oldSnapshot) {
        NSSet *objects = setObjectsBlock(oldSnapshot);
        return [oldSnapshot snapshotWithObjects:objects];
    }];
}



-(void)updateObjectsUsingBlock:(void(^)(BCOObjectStoreSnapshot *currentSnapshot, BCOUpdateCompletionHandler updateCompletionHandler))updateBlock
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
