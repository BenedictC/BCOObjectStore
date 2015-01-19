//
//  BCOObjectStoreCoordinator+Query.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 14/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import "BCOObjectStoreCoordinator.h"



@interface BCOObjectStoreCoordinator (Query)




//subgraphs:(root class)
//(start 'stations') //returns all objects of given type
//(start 'stations' 'Angel') //returns object of given type with given key
//-(id)performQuery:(NSString *)query;

// /Match by path: url:accounts[0].account.balance
//     //How do we handle collection ordering?
// //Match by class id: urn:account/1234
//     //We'd need to register classes and their id property
// 
// How do we do path matching?



@end
