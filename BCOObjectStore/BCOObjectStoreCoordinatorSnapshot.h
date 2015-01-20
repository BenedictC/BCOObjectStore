//
//  BCOObjectStoreCoordinatorSnapshot.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface BCOObjectStoreCoordinatorSnapshot : NSObject

-(instancetype)initWithStoresByName:(NSDictionary *)storesByName __attribute__((objc_designated_initializer));

@property(readonly) NSDictionary *storesByName;

-(NSArray *)fetchObjectsForIndexName:(NSString *)indexName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
-(NSArray *)fetchObjectsForIndexName:(NSString *)indexName matchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors fromStores:(NSArray *)storesNames;

@end
