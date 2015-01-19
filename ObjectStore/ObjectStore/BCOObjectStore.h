//
//  BCOObjectStore.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface BCOObjectStore : NSObject

-(instancetype)initWithObjects:(NSSet *)objects indexDescriptions:(NSSet *)indexDescriptions __attribute__((objc_designated_initializer));

@property(readonly) NSSet *objects;
@property(readonly) NSSet *indexDescriptions;

-(NSDictionary *)fetchObjectsOfClass:(Class)indexedClass;
-(id)fetchObjectOfClass:(Class)indexedClass uniqueID:(id)uniqueID;

@end
