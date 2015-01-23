//
//  BCOObjectStoreSnapshot.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



//@interface BCOObjectStoreSnapshot : NSObject
//
//-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions __attribute__((objc_designated_initializer));
//
//@property(readonly) NSSet *objects;
//@property(readonly) NSDictionary *indexDescriptions;
//
//-(NSArray *)fetchObjectsMatchingPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;
//-(NSArray *)fetchObjectsFromIndexNamed:(NSString *)indexName withKeyInArray:(NSArray *)keys sortDescriptors:(NSArray *)sortDescriptors;
//
//-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)objects;
//-(BCOObjectStoreSnapshot *)snapshotByRemovingObjects:(NSSet *)expiredObjects addingObjects:(NSSet *)freshObjects;
//
//@end



@interface BCOObjectStoreSnapshot : NSObject

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions __attribute__((objc_designated_initializer));

@property(readonly) NSSet *objects;
@property(readonly) NSDictionary *indexDescriptions;

-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)objects;
-(BCOObjectStoreSnapshot *)snapshotByRemovingObjects:(NSSet *)expiredObjects addingObjects:(NSSet *)freshObjects;

-(NSArray *)executeQuery:(NSString *)query;
-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable;

@end

