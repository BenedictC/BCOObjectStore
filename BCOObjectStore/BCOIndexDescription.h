//
//  BCOIndexDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOIndexValue.h"



@interface BCOIndexDescription : NSObject

-(instancetype)initWithIndexValueGenerator:(BCOIndexValueGenerator)generator valueComparator:(NSComparator)valueComparator __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) BCOIndexValueGenerator indexValueGenerator;
@property(nonatomic, copy, readonly) NSComparator valueComparator;

@end
