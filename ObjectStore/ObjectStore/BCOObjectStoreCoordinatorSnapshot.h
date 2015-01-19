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

-(NSDictionary *)fetchAllObjectsOfClass:(Class)indexedClass;
-(id)fetchObjectWithPrimaryID:(id)uniqueID class:(Class)indexedClass;

-(NSDictionary *)fetchAllObjectsOfClass:(Class)indexedClass fromStores:(NSArray *)storeNames;
-(id)fetchObjectWithPrimaryID:(id)primaryID class:(Class)indexedClass fromStores:(NSArray *)storeNames;

@end
