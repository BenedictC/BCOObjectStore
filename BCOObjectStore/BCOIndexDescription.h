//
//  BCOIndexDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



typedef id<NSCopying>(^BCOIndexer)(id object);



@interface BCOIndexDescription : NSObject

-(instancetype)initWithIndexer:(BCOIndexer)indexer isUnique:(BOOL)isUnique __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) BCOIndexer indexer;
@property(nonatomic, readonly, getter=isUnique) BOOL unique;

@end
