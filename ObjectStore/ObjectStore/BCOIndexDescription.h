//
//  BCOIndexDescription.h
//  BCOObjectStore
//
//  Created by Benedict Cohen on 13/10/2014.
//  Copyright (c) 2014 Benedict Cohen. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface BCOIndexDescription : NSObject

-(instancetype)initWithIndexedClass:(Class)indexedClass valueKeyPath:(NSString *)valueKeyPath __attribute__((objc_designated_initializer));

@property(nonatomic, copy, readonly) Class indexedClass;
@property(nonatomic, copy, readonly) NSString *valueKeyPath;

@end

