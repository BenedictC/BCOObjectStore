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



#pragma mark - BCOObjectStoreChangeHandler
@interface BCOObjectStoreChangeHandler : NSObject <BCOCallbackToken>
@property(atomic, copy) void(^changeHandler)(BCOObjectStoreSnapshot *oldContext, BCOObjectStoreSnapshot *newContext);
@property(atomic, copy) void(^unregisterHandler)(BCOObjectStoreChangeHandler* unregisteringChangeHandler);
@end



@implementation BCOObjectStoreChangeHandler

-(void)unregister
{
    if (self.unregisterHandler != NULL) self.unregisterHandler(self);
}



-(void)invokeChangeHandlerWithOldContext:(BCOObjectStoreSnapshot *)oldContext newContext:(BCOObjectStoreSnapshot *)newContext
{
    if (self.changeHandler != NULL) self.changeHandler(oldContext, newContext);
}

@end





#pragma mark - BCOObjectStore
@interface BCOObjectStore ()

//Init state
@property(atomic, readonly) dispatch_queue_t mutationQueue;

//'Mutable' state
@property(atomic, readonly) NSDictionary *indexDescriptions;
//Declared in the header but as id <BCOObjectStoreSnapshot>
//@property(atomic, readonly) BCOObjectStoreSnapshot *currentSnapshot;
@property(atomic, readonly) NSSet *changeHandlers;

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

    _indexDescriptions = [NSDictionary new];
    _snapshot = [[BCOObjectStoreSnapshot alloc] initWithObjects:[NSSet set] indexDescriptions:[NSDictionary dictionary]];
    _changeHandlers = [NSSet set];

    return self;
}



#pragma mark - 'properties'
typedef void(^Setter)(NSDictionary *indexDescriptions, BCOObjectStoreSnapshot *snapshot, NSSet *changeHandlers);
-(void)setState:(void(^)(BCOObjectStore *self, Setter setter))block
{
    Setter setter = ^(NSDictionary *indexDescriptions, BCOObjectStoreSnapshot *snapshot, NSSet *changeHandlers){
        _indexDescriptions = [indexDescriptions copy];
        _snapshot = snapshot;
        _changeHandlers = [changeHandlers copy];
    };

    BOOL shouldUseQueue = self.mutationQueue != NULL;
    if (shouldUseQueue) {
        dispatch_sync(self.mutationQueue, ^{
            block(self, setter);
        });
    } else { //Block which ever thread we're being called on.
        @synchronized(self) {
            block(self, setter);
        }
    }
}



#pragma mark - Configuring the store
-(void)setIndexDescription:(BCOIndexDescription *)indexDescription forName:(NSString *)indexName
{
    NSMutableDictionary *indexDescriptions = [NSMutableDictionary dictionaryWithObject:indexDescription forKey:indexName];

    [self setState:^(BCOObjectStore *self, Setter setter) {
        [indexDescriptions addEntriesFromDictionary:self.indexDescriptions];

        //Re-create all stores with the new object descriptions and re-run the queries
        BCOObjectStoreSnapshot *oldSnapshot = self.snapshot;
        BCOObjectStoreSnapshot *newSnapshot = [[BCOObjectStoreSnapshot alloc] initWithObjects:oldSnapshot.objects indexDescriptions:indexDescriptions];

        setter(indexDescriptions, newSnapshot, self.changeHandlers);

        [self invokeChangeHandlersWithOldContext:oldSnapshot newContext:newSnapshot];
    }];
}



#pragma mark - Setting stores content
-(void)setObjects:(NSSet *)objects
{
    [self setState:^(BCOObjectStore *self, Setter setter) {
        BCOObjectStoreSnapshot *oldSnapshot = self.snapshot;
        BCOObjectStoreSnapshot *newSnapshot = [[BCOObjectStoreSnapshot alloc] initWithObjects:objects indexDescriptions:oldSnapshot.indexDescriptions];

        setter(self.indexDescriptions, newSnapshot, self.changeHandlers);

        [self invokeChangeHandlersWithOldContext:oldSnapshot newContext:newSnapshot];
    }];
}



#pragma mark - Accessing objects
-(void)invokeChangeHandlersWithOldContext:(BCOObjectStoreSnapshot *)oldContext newContext:(BCOObjectStoreSnapshot *)newContext
{
    for (BCOObjectStoreChangeHandler *changeHandler in self.changeHandlers) {
        [changeHandler invokeChangeHandlerWithOldContext:oldContext newContext:newContext];
    }
}



-(id<BCOCallbackToken>)registerChangeHandler:(void(^)(BCOObjectStoreSnapshot *oldContext, BCOObjectStoreSnapshot *newContext))changeHandlerBlock
{
    //Create a new change handler
    BCOObjectStoreChangeHandler *changeHandler = [BCOObjectStoreChangeHandler new];
    changeHandler.changeHandler = changeHandlerBlock;
    __weak typeof(self) weakSelf = self;
    changeHandler.unregisterHandler = ^(BCOObjectStoreChangeHandler *unregisteringChangeHandler){
        [weakSelf unregisterChangeHandler:unregisteringChangeHandler];
    };

    //Store the changeHandler
    NSMutableSet *changeHandlers = [NSMutableSet setWithObject:changeHandler];
    [self setState:^(BCOObjectStore *self, Setter setter) {
        [changeHandlers unionSet:self.changeHandlers];

        setter(self.indexDescriptions, self.snapshot, changeHandlers);
    }];

    return changeHandler;
}


-(void)unregisterChangeHandler:(BCOObjectStoreChangeHandler *)changeHandler
{
    [self setState:^(BCOObjectStore *self, Setter setter) {
        NSMutableSet *changeHandlers = [self.changeHandlers mutableCopy];
        [changeHandlers removeObject:changeHandler];

        setter(self.indexDescriptions, self.snapshot, changeHandlers);
    }];
}

@end
