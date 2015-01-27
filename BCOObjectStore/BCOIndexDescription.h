//
//  BCOIndexDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOKeyGenerator.h"



@interface BCOIndexDescription : NSObject

-(instancetype)initWithIndexKeyGenerator:(BCOKeyGenerator)indexer keyComparator:(NSComparator)keyComparator __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) BCOKeyGenerator indexKeyGenerator;
@property(nonatomic, copy, readonly) NSComparator keyComparator;

@end
