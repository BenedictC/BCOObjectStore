//
//  BCOObjectStoreSnapshot.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 11/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BCOIndexDescription;



@interface BCOObjectStoreSnapshot : NSObject

//Snapshot creation
+(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)objects indexDescriptions:(NSDictionary *)indexDescriptions;
-(BCOObjectStoreSnapshot *)snapshotByAddingIndexDescription:(BCOIndexDescription *)indexDescription withIndexName:(NSString *)indexName;
-(BCOObjectStoreSnapshot *)snapshotWithObjects:(NSSet *)newObjects;
-(BCOObjectStoreSnapshot *)snapshotByInsertingObjects:(NSSet *)freshObjects deletingObjects:(NSSet *)expiredObjects;



//Querying
-(NSArray *)executeQuery:(NSString *)query;
-(NSArray *)executeQuery:(NSString *)query subsitutionVariable:(NSDictionary *)subsitutionVariable;

@end

