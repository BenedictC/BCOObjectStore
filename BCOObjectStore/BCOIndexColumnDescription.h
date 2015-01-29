//
//  BCOIndexColumnDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOColumnKey.h"



@interface BCOIndexColumnDescription : NSObject

-(instancetype)initWithIndexKeyGenerator:(BCOColumnKeyGenerator)indexer keyComparator:(NSComparator)keyComparator __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) BCOColumnKeyGenerator indexKeyGenerator;
@property(nonatomic, copy, readonly) NSComparator keyComparator;

@end
