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
typedef void(^Setter)(BCOObjectStoreSnapshot *snapshot);
-(void)setSnapshot:(void(^)(BCOObjectStore *self, Setter setter))block
{
    Setter setter = ^(BCOObjectStoreSnapshot *snapshot){
        _snapshot = snapshot;
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

    [self setSnapshot:^(BCOObjectStore *self, Setter setter) {
        BCOObjectStoreSnapshot *oldSnapshot = self.snapshot;
        NSMutableDictionary *indexDescriptions = [NSMutableDictionary dictionaryWithObject:indexDescription forKey:indexName];
        [indexDescriptions addEntriesFromDictionary:oldSnapshot.indexDescriptions];

        //TODO: Create a method on BCOObjectStoreSnapshot that copies the existing indexes and only runs the new one
        BCOObjectStoreSnapshot *newSnapshot = [[BCOObjectStoreSnapshot alloc] initWithObjects:oldSnapshot.objects indexDescriptions:indexDescriptions];

        setter(newSnapshot);
    }];
}



#pragma mark - Setting stores content
-(void)setObjects:(NSSet *)objects
{
    [self setSnapshot:^(BCOObjectStore *self, Setter setter) {
        BCOObjectStoreSnapshot *oldSnapshot = self.snapshot;
        BCOObjectStoreSnapshot *newSnapshot = [oldSnapshot snapshotWithObjects:objects];

        setter(newSnapshot);
    }];
}

@end
