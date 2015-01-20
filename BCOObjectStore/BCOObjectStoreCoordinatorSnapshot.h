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

-(NSArray *)fetchObjectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
-(NSArray *)fetchObjectsFromIndexNamed:(NSString *)indexName withKeyInArray:(NSArray *)keys sortDescriptors:(NSArray *)sortDescriptors;

@end
