//
//  BCOObjectStoreCoordinator.m
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreCoordinator.h"

#import "BCOObjectStore.h"
#import "BCOObjectStoreCoordinatorSnapshot.h"
#import "BCOIndexDescription.h"



#pragma mark - BCOObjectStoreCoordinatorChangeHandler
@interface BCOObjectStoreCoordinatorChangeHandler : NSObject <BCOCallbackToken>
@property(atomic, copy) void(^changeHandler)(BCOObjectStoreCoordinatorSnapshot *oldContext, BCOObjectStoreCoordinatorSnapshot *newContext);
@property(atomic, copy) void(^unregisterHandler)(BCOObjectStoreCoordinatorChangeHandler* unregisteringChangeHandler);
@end



@implementation BCOObjectStoreCoordinatorChangeHandler

-(void)unregister
{
    if (self.unregisterHandler != NULL) self.unregisterHandler(self);
}



-(void)invokeChangeHandlerWithOldContext:(BCOObjectStoreCoordinatorSnapshot *)oldContext newContext:(BCOObjectStoreCoordinatorSnapshot *)newContext
{
    if (self.changeHandler != NULL) self.changeHandler(oldContext, newContext);
}

@end





#pragma mark - BCOObjectStoreCoordinator
@interface BCOObjectStoreCoordinator ()

//Init state
@property(atomic, readonly) dispatch_queue_t mutationQueue;

//'Mutable' state
@property(atomic, readonly) NSDictionary *indexDescriptions;
//Declared in the header but as id <BCOObjectStoreCoordinatorSnapshot>
//@property(atomic, readonly) BCOObjectStoreCoordinatorSnapshot *currentSnapshot;
@property(atomic, readonly) NSSet *changeHandlers;

@end



@implementation BCOObjectStoreCoordinator

#pragma mark - instance life cycle
+(instancetype)objectStoreCoordinatorWithBackgroundQueue
{
    id instance = [self alloc];
    NSString *label = [NSString stringWithFormat:@"%p - %@: mutation queue", instance, NSStringFromClass(self)];
    dispatch_queue_t queue = dispatch_queue_create(label.UTF8String, 0);

    return [[self alloc] initWithDispatchQueue:queue];
}



+(instancetype)objectStoreCoordinatorWithMainQueue
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
    _snapshot = [[BCOObjectStoreCoordinatorSnapshot alloc] initWithStoresByName:[NSDictionary new]];
    _changeHandlers = [NSSet set];

    return self;
}



#pragma mark - 'properties'
typedef void(^Setter)(NSDictionary *indexDescriptions, BCOObjectStoreCoordinatorSnapshot *snapshot, NSSet *changeHandlers);
-(void)setState:(void(^)(BCOObjectStoreCoordinator *self, Setter setter))block
{
    Setter setter = ^(NSDictionary *indexDescriptions, BCOObjectStoreCoordinatorSnapshot *snapshot, NSSet *changeHandlers){
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

    [self setState:^(BCOObjectStoreCoordinator *self, Setter setter) {
        [indexDescriptions addEntriesFromDictionary:self.indexDescriptions];

        //Re-create all stores with the new object descriptions and re-run the queries
        NSMutableDictionary *storesByName = [NSMutableDictionary new];
        [self.snapshot.storesByName enumerateKeysAndObjectsUsingBlock:^(NSString *name, BCOObjectStore *store, BOOL *stop) {
            storesByName[name] = [[BCOObjectStore alloc] initWithObjects:store.objects indexDescriptions:indexDescriptions];
        }];
        BCOObjectStoreCoordinatorSnapshot *oldSnapshot = self.snapshot;
        BCOObjectStoreCoordinatorSnapshot *newSnapshot = [[BCOObjectStoreCoordinatorSnapshot alloc] initWithStoresByName:storesByName];

        setter(indexDescriptions, newSnapshot, self.changeHandlers);

        [self invokeChangeHandlersWithOldContext:oldSnapshot newContext:newSnapshot];
    }];
}



#pragma mark - Setting stores content
-(void)setObjects:(NSSet *)objects forStoreWithName:(NSString *)storeName
{
    [self setState:^(BCOObjectStoreCoordinator *self, Setter setter) {
        NSMutableDictionary *storesByName = [self.snapshot.storesByName mutableCopy];
        storesByName[storeName] = [[BCOObjectStore alloc] initWithObjects:objects indexDescriptions:self.indexDescriptions];

        BCOObjectStoreCoordinatorSnapshot *oldSnapshot = self.snapshot;
        BCOObjectStoreCoordinatorSnapshot *newSnapshot = [[BCOObjectStoreCoordinatorSnapshot alloc] initWithStoresByName:storesByName];

        setter(self.indexDescriptions, newSnapshot, self.changeHandlers);

        [self invokeChangeHandlersWithOldContext:oldSnapshot newContext:newSnapshot];
    }];
}



#pragma mark - Accessing objects
-(void)invokeChangeHandlersWithOldContext:(BCOObjectStoreCoordinatorSnapshot *)oldContext newContext:(BCOObjectStoreCoordinatorSnapshot *)newContext
{
    for (BCOObjectStoreCoordinatorChangeHandler *changeHandler in self.changeHandlers) {
        [changeHandler invokeChangeHandlerWithOldContext:oldContext newContext:newContext];
    }
}



-(id<BCOCallbackToken>)registerChangeHandler:(void(^)(BCOObjectStoreCoordinatorSnapshot *oldContext, BCOObjectStoreCoordinatorSnapshot *newContext))changeHandlerBlock
{
    //Create a new change handler
    BCOObjectStoreCoordinatorChangeHandler *changeHandler = [BCOObjectStoreCoordinatorChangeHandler new];
    changeHandler.changeHandler = changeHandlerBlock;
    __weak typeof(self) weakSelf = self;
    changeHandler.unregisterHandler = ^(BCOObjectStoreCoordinatorChangeHandler *unregisteringChangeHandler){
        [weakSelf unregisterChangeHandler:unregisteringChangeHandler];
    };

    //Store the changeHandler
    NSMutableSet *changeHandlers = [NSMutableSet setWithObject:changeHandler];
    [self setState:^(BCOObjectStoreCoordinator *self, Setter setter) {
        [changeHandlers unionSet:self.changeHandlers];

        setter(self.indexDescriptions, self.snapshot, changeHandlers);
    }];

    return changeHandler;
}


-(void)unregisterChangeHandler:(BCOObjectStoreCoordinatorChangeHandler *)changeHandler
{
    [self setState:^(BCOObjectStoreCoordinator *self, Setter setter) {
        NSMutableSet *changeHandlers = [self.changeHandlers mutableCopy];
        [changeHandlers removeObject:changeHandler];

        setter(self.indexDescriptions, self.snapshot, changeHandlers);
    }];
}

@end
