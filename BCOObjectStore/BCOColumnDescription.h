//
//  BCOColumnDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BCOColumnValue.h"



@interface BCOColumnDescription : NSObject

-(instancetype)initWithColumnValueGenerator:(BCOColumnValueGenerator)generator valueComparator:(NSComparator)valueComparator __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) BCOColumnValueGenerator columnValueGenerator;
@property(nonatomic, copy, readonly) NSComparator valueComparator;

@end
